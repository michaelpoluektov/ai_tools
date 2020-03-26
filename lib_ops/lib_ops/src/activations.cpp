// Copyright (c) 2020, XMOS Ltd, All rights reserved
#include "lib_ops/api/activations.h"

extern "C" {
#include "lib_nn/api/nn_operator.h"
}

namespace xcore {
namespace activations {

XCoreStatus Lookup8::Eval(uint8_t* Y, const uint8_t* X, const uint8_t* lut,
                          const int32_t length) {
  lookup8(Y, X, lut, length);

  return kXCoreOk;
}

}  // namespace activations
}  // namespace xcore