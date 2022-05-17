// RUN: xcore-opt --mlir-io %s --xcore-apply-loadconstantop-patterns --xcore-flash-image-file=/dev/null --xcore-load-externally-if-larger=0 | FileCheck %s

// RUN: xcore-opt --mlir-io %s --xcore-apply-loadconstantop-patterns --xcore-flash-image-file=/dev/null --xcore-load-externally-if-larger=16 | FileCheck %s -check-prefix=LARGER-CHECK

// CHECK-LABEL: valid
func @valid(%arg0: tensor<?x4x8x1x!quant.uniform<i8:f32, 0.0078160231932997704>>) -> tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>> attributes {tf.entry_function = {inputs = "flatten_input", outputs = "Identity"}} {
  %cst = arith.constant dense<[1, 2, 3, 4, 5, 6, 7, 8, 9, 0]> : tensor<10xi8>
  %cst_0 = arith.constant dense<[[11, 12, 13, 14, 15, 16, 17, 18, 19, 10]]> : tensor<1x10xi16>
  %cst_1 = arith.constant dense<[-1, 1, 1, 32]> : tensor<4xi64>
  %cst_2 = arith.constant dense<[-1, 32]> : tensor<2xi64>
  %0 = "tfl.pseudo_const"() {value = dense<[-1, 32]> : tensor<2xi32>} : () -> tensor<2xi32>
  %1 = "tfl.reshape"(%arg0, %0) : (tensor<?x4x8x1x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<2xi32>) -> tensor<?x32x!quant.uniform<i8:f32, 0.0078160231932997704>>
  %2 = "tfl.reshape"(%1, %cst_1) : (tensor<?x32x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<4xi64>) -> tensor<?x1x1x32x!quant.uniform<i8:f32, 0.0078160231932997704>>
  // CHECK: xc.ld_constant
  // CHECK: xc.ld_constant
  // CHECK: xc.conv2d_v2
  %3 = "xc.conv2d_v2"(%2, %cst, %cst_0) {abstract_kernel_params = ["\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00 \00\00\00"], aggregate_fn_param = " \08\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00 \08\00\00\CA~=\18\FC\1C\86\1B\BE\0D\B0U\13\CC\16\B57\DA*\22I0\F9~\88c\D8K\E2\A1\F3P^\16W\8B\C0\85\F8\F5[\AB\825\05\DC\97, rQ\FCf\F6\A1\A2\B3\7F+\E5\F9\04\E1\CA\05\A8\F6\F6Iv\9BQ\B6M\B9\89\EA\1F\B1\1C\AD\8D-,C\BB\DF^\F0\1C>\82\E9\99G\AA\BB\12\D5c*\89m\03\9FP\97\14\AFP\AA\D42\A2\8C3\87P%\09M\DC\0CB\A2p\82y\BF|\13\A6\C4\F5%\D3WhW\D1\00#~\F4_\A5\F5\A2f4\85]k\8A\DD\93\0B\0B\DF\04\DD\82\AB\8A\97\91\DD\D4X\83\8A=_v=\85\A2\19\87\A4\E6\1A?F=\CC~\06\83\D1\DBU\A0\EC\82=\84%M\18\E1\D1\AB\C8\1D\8B\BE\D6h\C8\E8\F1\DD\EE`\F3\E1h75\A3\87\04/'\96\C9\10\AB\A2\147\FD\B3\C6\AE\08\F4\83JoK\93\CD\8EZ\\S\CB<\BEv[\CE\CA\B1\FB\FC\0AR\E4sV\04x\EA\99\A8z \FE+e\C9\84\AD\F2E\89\88\8B\C6\C5wa{>\BA\CF\E6\005\A5:\9F\8B\CA2\07\D0=\F2Jz\85\B7\17\CA\A5fM\DC\9F\91\1E\1Aj\DF\ED\A8I\DC\1DW\90\19\92\FA\84\11\15\9C\B7\AC\02\BD\03/\05\BFxk\BF\E4\AE\A2'p\F4d^\988M_\D7\B4!\CDn4Q\93\AE\D9\AC\B6K\0A\C4\D6\A2\16i<\B1M\A1\F2N\AD*\C0O\0CVs\E9\FA\CF\DBWEZw\9F\AF\A5<L\1E\F2x\15W\96\19g\D9\CCG\19d?2\9E\CD(\DD'\FD>bu\04{\A1!\EF\8C$&u\A9\1F&\A6\E6\22=\AEB\B8\D9\8A\F8\D7l\12\DA\09\98\10\07AP\A9yv\BC[xI\CAs\D6\A1,\E4\EF\DD\9E\F6\FA\D4\B9\B3\A6\B5j\A1&)d\0D\DA\DFV\E8\F0\F0f+\D5\AB\7Fq/\89\9A\15\81\BA2\ED`\EB\88\12\D4\C7\90i?\E7\98\AB:\E5\E2y\87\EA\93s\F4'\CBb\B1^\893\C3\C6\B6\BA\96$+\AF\EA\99\17\CE+O\B80\AC\10\DE\DCIl\B1\CATB\EA/\E9\AF\99g\00\01Y\BF/\82\A6\BF\EF0\D5k\A2\FA\1BM$\9A~@|\EFu\9By\A9>\99\E1;\0F\053G#\0B\A4\A8\1A^\E8W\07\EB`\98s\D4ZtV\1D\82A\C2\FF\13\E0\EF\F6MRP\A8\CE\22`\FC\BE\82\19\04}\B7\ED\FE\D8\197Yj\F5\BA^#f\C3\05\8F|vK\AB\E0k\D6qx\F0U\95{\D0\F1\F2\CA\B1N\FEI\C0\1990\04@\EB\0C\99\B4\9BjN\15\03\C0rd\D2\84\BA\96HZ\8CN:\8C\07@A\8C\B1DFq\C4u m\88b\10?Us\8F\8A\9C\BC\C9\A5\\\84\0E(f\8CF*\BF\FC\F72\BC\0A=k\AEG\0C2sq\B6X\07\FE\9A\22\F9c\03\BC\F7\15+r\EFOy\9E\E3\00\11#h_\A9\96\11\C5\FD\B9\82\EA,\D60}\96Z\8A .\0B\CB\D3/\AF\EC5\\\AA\DC#\8DM\8C\A7\94[TP\AD\BD+\16\87\06/8\06\D6[\C9 \F8\83C\869$EU\\\C6e\155\C7cK\CD\D4\1C\0A\19\A6E\A7\12\BC\DB\06\B5\EC\F2]rIn\D2\B6\B5DA\DA\C3N46M\A4\BE\10\16\12\C1\D7\CA=RRf\1D\A5\F6\A8\B5,\E6\0Bj\FF\EE\86C;D\E2\FD\97\08\A7\E9\06G\FBM\ECS\BE6Qe%1\14\81N\1F\DD7X\DF\9A\9D\F40\E3\1B\9F\F1\B8\A5o\AF\DB2\DF\B4\1DR\F6y\B0<\AD\CB\EAYD\D5v;M\EC\8F>f@\A6\8D,,\0EiJ\E0c\E6\E5\E8\DBR\94\E6%\03v\9DO\0A\96\BAX}\8E\CF\09\94|\06j\84\B3\FE\81H\A4-\F0\A65W\02?\BB6\B4\0A\D8B|\91\D3\22\BEw\E32\C4G#\EA\16\01|\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", conv2d_kernel_type = "ValidDirect", memcpy_fn_param = " \00\00\00 \00\00\00", output_transform_fn_param = "\E4\00\00\00 \00\00\00 \00\00\00\00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\00\00\00\00\C1\0F\A9\BD\22\03\D5\F9u\F5\B9\B8\DA\00g\F3@\B1\C1\EBQ\0A4\DF\ED\16\BD\01{\10\12\E0.\D3S\D57\12\B7\03\D1\10u\E6\AE\E0\11\F0m\FD\A3\12\A1\19\9A\D6-\BC1\EE\C3\C5\7F\EF\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk", scratch_bytes = 0 : i32, thread_count = 1 : i32} : (tensor<?x1x1x32x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<10xi8>, tensor<1x10xi16>) -> tensor<?x1x1x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
  %4 = "tfl.reshape"(%3, %cst_2) : (tensor<?x1x1x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>, tensor<2xi64>) -> tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
  return %4 : tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
}

// -----

// LARGER-CHECK-LABEL: valid2
func @valid2(%arg0: tensor<?x4x8x1x!quant.uniform<i8:f32, 0.0078160231932997704>>) -> tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>> attributes {tf.entry_function = {inputs = "flatten_input", outputs = "Identity"}} {
  %cst = arith.constant dense<[1, 2, 3, 4, 5, 6, 7, 8, 9, 0]> : tensor<10xi8>
  %cst_0 = arith.constant dense<[[11, 12, 13, 14, 15, 16, 17, 18, 19, 10]]> : tensor<1x10xi16>
  %cst_1 = arith.constant dense<[-1, 1, 1, 32]> : tensor<4xi64>
  %cst_2 = arith.constant dense<[-1, 32]> : tensor<2xi64>
  %0 = "tfl.pseudo_const"() {value = dense<[-1, 32]> : tensor<2xi32>} : () -> tensor<2xi32>
  %1 = "tfl.reshape"(%arg0, %0) : (tensor<?x4x8x1x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<2xi32>) -> tensor<?x32x!quant.uniform<i8:f32, 0.0078160231932997704>>
  %2 = "tfl.reshape"(%1, %cst_1) : (tensor<?x32x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<4xi64>) -> tensor<?x1x1x32x!quant.uniform<i8:f32, 0.0078160231932997704>>
  // LARGER-CHECK: xc.ld_constant
  // LARGER-CHECK-NOT: xc.ld_constant
  // LARGER-CHECK: xc.conv2d_v2
  %3 = "xc.conv2d_v2"(%2, %cst, %cst_0) {abstract_kernel_params = ["\00\00\00\00\01\00\00\00\00\00\00\00\01\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00 \00\00\00"], aggregate_fn_param = " \08\00\00\00\02\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00 \08\00\00\CA~=\18\FC\1C\86\1B\BE\0D\B0U\13\CC\16\B57\DA*\22I0\F9~\88c\D8K\E2\A1\F3P^\16W\8B\C0\85\F8\F5[\AB\825\05\DC\97, rQ\FCf\F6\A1\A2\B3\7F+\E5\F9\04\E1\CA\05\A8\F6\F6Iv\9BQ\B6M\B9\89\EA\1F\B1\1C\AD\8D-,C\BB\DF^\F0\1C>\82\E9\99G\AA\BB\12\D5c*\89m\03\9FP\97\14\AFP\AA\D42\A2\8C3\87P%\09M\DC\0CB\A2p\82y\BF|\13\A6\C4\F5%\D3WhW\D1\00#~\F4_\A5\F5\A2f4\85]k\8A\DD\93\0B\0B\DF\04\DD\82\AB\8A\97\91\DD\D4X\83\8A=_v=\85\A2\19\87\A4\E6\1A?F=\CC~\06\83\D1\DBU\A0\EC\82=\84%M\18\E1\D1\AB\C8\1D\8B\BE\D6h\C8\E8\F1\DD\EE`\F3\E1h75\A3\87\04/'\96\C9\10\AB\A2\147\FD\B3\C6\AE\08\F4\83JoK\93\CD\8EZ\\S\CB<\BEv[\CE\CA\B1\FB\FC\0AR\E4sV\04x\EA\99\A8z \FE+e\C9\84\AD\F2E\89\88\8B\C6\C5wa{>\BA\CF\E6\005\A5:\9F\8B\CA2\07\D0=\F2Jz\85\B7\17\CA\A5fM\DC\9F\91\1E\1Aj\DF\ED\A8I\DC\1DW\90\19\92\FA\84\11\15\9C\B7\AC\02\BD\03/\05\BFxk\BF\E4\AE\A2'p\F4d^\988M_\D7\B4!\CDn4Q\93\AE\D9\AC\B6K\0A\C4\D6\A2\16i<\B1M\A1\F2N\AD*\C0O\0CVs\E9\FA\CF\DBWEZw\9F\AF\A5<L\1E\F2x\15W\96\19g\D9\CCG\19d?2\9E\CD(\DD'\FD>bu\04{\A1!\EF\8C$&u\A9\1F&\A6\E6\22=\AEB\B8\D9\8A\F8\D7l\12\DA\09\98\10\07AP\A9yv\BC[xI\CAs\D6\A1,\E4\EF\DD\9E\F6\FA\D4\B9\B3\A6\B5j\A1&)d\0D\DA\DFV\E8\F0\F0f+\D5\AB\7Fq/\89\9A\15\81\BA2\ED`\EB\88\12\D4\C7\90i?\E7\98\AB:\E5\E2y\87\EA\93s\F4'\CBb\B1^\893\C3\C6\B6\BA\96$+\AF\EA\99\17\CE+O\B80\AC\10\DE\DCIl\B1\CATB\EA/\E9\AF\99g\00\01Y\BF/\82\A6\BF\EF0\D5k\A2\FA\1BM$\9A~@|\EFu\9By\A9>\99\E1;\0F\053G#\0B\A4\A8\1A^\E8W\07\EB`\98s\D4ZtV\1D\82A\C2\FF\13\E0\EF\F6MRP\A8\CE\22`\FC\BE\82\19\04}\B7\ED\FE\D8\197Yj\F5\BA^#f\C3\05\8F|vK\AB\E0k\D6qx\F0U\95{\D0\F1\F2\CA\B1N\FEI\C0\1990\04@\EB\0C\99\B4\9BjN\15\03\C0rd\D2\84\BA\96HZ\8CN:\8C\07@A\8C\B1DFq\C4u m\88b\10?Us\8F\8A\9C\BC\C9\A5\\\84\0E(f\8CF*\BF\FC\F72\BC\0A=k\AEG\0C2sq\B6X\07\FE\9A\22\F9c\03\BC\F7\15+r\EFOy\9E\E3\00\11#h_\A9\96\11\C5\FD\B9\82\EA,\D60}\96Z\8A .\0B\CB\D3/\AF\EC5\\\AA\DC#\8DM\8C\A7\94[TP\AD\BD+\16\87\06/8\06\D6[\C9 \F8\83C\869$EU\\\C6e\155\C7cK\CD\D4\1C\0A\19\A6E\A7\12\BC\DB\06\B5\EC\F2]rIn\D2\B6\B5DA\DA\C3N46M\A4\BE\10\16\12\C1\D7\CA=RRf\1D\A5\F6\A8\B5,\E6\0Bj\FF\EE\86C;D\E2\FD\97\08\A7\E9\06G\FBM\ECS\BE6Qe%1\14\81N\1F\DD7X\DF\9A\9D\F40\E3\1B\9F\F1\B8\A5o\AF\DB2\DF\B4\1DR\F6y\B0<\AD\CB\EAYD\D5v;M\EC\8F>f@\A6\8D,,\0EiJ\E0c\E6\E5\E8\DBR\94\E6%\03v\9DO\0A\96\BAX}\8E\CF\09\94|\06j\84\B3\FE\81H\A4-\F0\A65W\02?\BB6\B4\0A\D8B|\91\D3\22\BEw\E32\C4G#\EA\16\01|\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00", conv2d_kernel_type = "ValidDirect", memcpy_fn_param = " \00\00\00 \00\00\00", output_transform_fn_param = "\E4\00\00\00 \00\00\00 \00\00\00\00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \00 \0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\0E\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\02\00\00\00\00\00\C1\0F\A9\BD\22\03\D5\F9u\F5\B9\B8\DA\00g\F3@\B1\C1\EBQ\0A4\DF\ED\16\BD\01{\10\12\E0.\D3S\D57\12\B7\03\D1\10u\E6\AE\E0\11\F0m\FD\A3\12\A1\19\9A\D6-\BC1\EE\C3\C5\7F\EF\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk\FBk", scratch_bytes = 0 : i32, thread_count = 1 : i32} : (tensor<?x1x1x32x!quant.uniform<i8:f32, 0.0078160231932997704>>, tensor<10xi8>, tensor<1x10xi16>) -> tensor<?x1x1x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
  %4 = "tfl.reshape"(%3, %cst_2) : (tensor<?x1x1x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>, tensor<2xi64>) -> tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
  return %4 : tensor<?x32x!quant.uniform<i8:f32, 0.037329975515604019:-13>>
}
