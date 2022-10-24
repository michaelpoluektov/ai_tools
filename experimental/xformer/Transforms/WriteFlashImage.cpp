// Copyright 2021 XMOS LIMITED. This Software is subject to the terms of the
// XMOS Public License: Version 1

#include "IR/XCoreOps.h"
#include "Transforms/Options.h"
#include "Utils/FileIO.h"

#include "mlir/Pass/Pass.h"
#include "mlir/Support/FileUtilities.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "tensorflow/compiler/mlir/lite/ir/tfl_ops.h"
#include "llvm/Support/ToolOutputFile.h"

namespace mlir {
namespace xcore {

namespace {
// Write flash image
struct WriteFlashImage
    : public PassWrapper<WriteFlashImage, OperationPass<func::FuncOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(WriteFlashImage)

  void getDependentDialects(DialectRegistry &registry) const final {
    registry.insert<XCoreDialect>();
  }
  StringRef getArgument() const final { return "xcore-write-flash-image"; }
  StringRef getDescription() const final { return "Write flash image"; }
  void runOnOperation() override;
};

struct WriteFlashImagePattern : public OpRewritePattern<LoadConstantOp> {
  WriteFlashImagePattern(std::vector<std::vector<char>> *tensorsVec,
                         MLIRContext *context)
      : OpRewritePattern<LoadConstantOp>(context), tensorsVec_(tensorsVec) {}

  LogicalResult matchAndRewrite(LoadConstantOp loadOp,
                                PatternRewriter &rewriter) const override {
    DenseElementsAttr attr;
    if (loadOp.input()
            .getType()
            .cast<ShapedType>()
            .getElementType()
            .isa<quant::QuantizedType>()) {
      auto qConstOp = dyn_cast<TFL::QConstOp>(loadOp.input().getDefiningOp());
      attr = qConstOp.value().template cast<DenseElementsAttr>();
    } else if (!matchPattern(loadOp.input(), m_Constant(&attr))) {
      return failure();
    }

    std::vector<char> tensorData;
    int n = attr.isSplat() ? attr.getNumElements() : 1;
    for (int i = 0; i < n; ++i) {
      tensorData.insert(tensorData.end(), attr.getRawData().begin(),
                        attr.getRawData().end());
    }

    int address = 0;
    for (auto const &t : *tensorsVec_) {
      address += t.size();
    }

    // Create a LoadFlashOp with data addr and tensor size
    auto loadFlashOp = rewriter.create<LoadFlashOp>(
        loadOp.getLoc(), loadOp.getType(), address, tensorData.size());
    tensorsVec_->push_back(tensorData);

    // Replace the LoadOp with the new LoadFlashOp
    rewriter.replaceOp(loadOp, loadFlashOp.output());
    return success();
  }

private:
  std::vector<std::vector<char>> *tensorsVec_;
};

void WriteFlashImage::runOnOperation() {
  func::FuncOp f = getOperation();
  if (flashImageFilenameOption.empty()) {
    f.emitError("Flash image file option should be provided to run this pass!");
    signalPassFailure();
    return;
  }

  auto *ctx = &getContext();
  func::FuncOp func = getOperation();
  // For each LoadOp in the graph, save the tensor data, and replace the LoadOp
  // with a LoadFlashOp
  std::vector<std::vector<char>> tensorsVec;
  RewritePatternSet patterns(ctx);
  patterns.insert<WriteFlashImagePattern>(&tensorsVec, ctx);
  (void)applyPatternsAndFoldGreedily(func, std::move(patterns));

  // Write tensor data to flash image file
  if (failed(
          utils::writeFlashImageToFile(flashImageFilenameOption, tensorsVec))) {
    f.emitError("Failed to write flash image!");
    signalPassFailure();
    return;
  }
}
} // namespace

// Creates an instance of the WriteFlashImage pass.
std::unique_ptr<OperationPass<func::FuncOp>> createWriteFlashImagePass() {
  return std::make_unique<WriteFlashImage>();
}

static PassRegistration<WriteFlashImage> pass;

} // namespace xcore
} // namespace mlir
