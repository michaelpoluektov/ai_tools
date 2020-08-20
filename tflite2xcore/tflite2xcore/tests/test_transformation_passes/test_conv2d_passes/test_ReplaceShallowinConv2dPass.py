# Copyright (c) 2019, XMOS Ltd, All rights reserved

import pytest

from copy import deepcopy

from tflite2xcore.pass_manager import ModelTransformationPass
from tflite2xcore.xcore_model import XCOREModel
from tflite2xcore.xcore_schema import XCOREOpCodes
from tflite2xcore.transformation_passes import ReplaceShallowinConv2dPass

from tflite2xcore.tests.test_transformation_passes.model_builders import build_conv2d
from .conftest import (
    PARAMS,
    _test_non_matching_params,
    test_matching_params,
    test_non_matching_output_channels,
    test_non_matching_input_channels,
    test_non_matching_tensors,
)
from .test_ReplaceDeepConv2dPass import test_mutate as _test_mutate


#  ----------------------------------------------------------------------------
#                              PARAMETER VALUES
#  ----------------------------------------------------------------------------

PARAMS = deepcopy(PARAMS)

PARAMS["extended"].update(
    {"input_channels": list(range(4, 36, 4)), "kernel_width": list(range(1, 9))}
)

PARAMS["default"].update({"input_channels": [4, 8, 16], "kernel_width": [2, 3, 5]})

PARAMS["smoke"].update({"input_channels": [4, 8], "kernel_width": [3, 5]})

for k in PARAMS:
    all_tails = [
        (kw, cin)
        for cin in PARAMS[k]["input_channels"]
        for kw in PARAMS[k]["kernel_width"]
    ]
    PARAMS[k].update(
        weight_tail=[t for t in all_tails if t[0] * t[1] <= 32],
        non_matching_weight_tail=[t for t in all_tails if t[0] * t[1] > 32],
    )


#  ----------------------------------------------------------------------------
#                                   FIXTURES
#  ----------------------------------------------------------------------------


@pytest.fixture()
def build_model():
    return build_conv2d


@pytest.fixture()
def trf_pass():
    return ReplaceShallowinConv2dPass()


@pytest.fixture()
def weight_shape(output_channels, kernel_height, weight_tail):
    return [output_channels, kernel_height, *weight_tail]


@pytest.fixture()
def model(weight_shape, input_size, padding, strides):
    return build_conv2d(
        weight_shape=weight_shape,
        input_size=input_size,
        padding=padding,
        strides=strides,
    )


@pytest.fixture()
def custom_opcode() -> XCOREOpCodes:
    return XCOREOpCodes.XC_conv2d_shallowin


#  ----------------------------------------------------------------------------
#                                   TESTS
#  ----------------------------------------------------------------------------


def test_mutate(
    trf_pass: ModelTransformationPass, model: XCOREModel, custom_opcode: XCOREOpCodes
) -> None:
    subgraph = model.subgraphs[0]
    K_w = subgraph.operators[0].inputs[1].shape[2]

    _test_mutate(trf_pass, model, custom_opcode)

    custom_options = subgraph.operators[-1].custom_options
    assert "Kw" in custom_options
    assert custom_options["Kw"] == K_w


def test_non_matching_weight_tail(
    trf_pass,
    build_model,
    output_channels,
    kernel_height,
    non_matching_weight_tail,
    input_size,
    padding,
    strides,
):
    model = build_model(
        weight_shape=[output_channels, kernel_height, *non_matching_weight_tail],
        input_size=input_size,
        padding=padding,
        strides=strides,
    )
    _test_non_matching_params(trf_pass, model)


if __name__ == "__main__":
    pytest.main()
