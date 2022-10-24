package(
    default_visibility = ["//visibility:public"],
)

cc_library(
    name = "nn_lib",
    hdrs = glob(["lib_nn/api/*.h*"]) + 
           glob(["lib_nn/api/geom/*.h*"]) + 
           glob(["lib_nn/src/asm/*.h*"]) + 
           glob(["lib_nn/src/*.h*"]),
    srcs = glob(["lib_nn/src/c/*.c"]) +
           glob(["lib_nn/src/c/util/depthwise/*.c"]) +
           glob(["lib_nn/src/c/util/deep/*.c"]) +
           glob(["lib_nn/src/c/util/binary/*.c"]) +
           glob(["lib_nn/src/c/util/shallow/*.c"]) +
           glob(["lib_nn/src/asm/*.c"]) +
           glob(["lib_nn/src/cpp/*.cpp"]) + 
           glob(["lib_nn/src/cpp/filt2d/*.cpp"]) + 
           glob(["lib_nn/src/cpp/filt2d/geom/*.cpp"]),
    includes = ["../../external/lib_nn/lib_nn/api"],
    local_defines = ["NN_USE_REF"],
    deps = [],
    alwayslink = 1,
)
