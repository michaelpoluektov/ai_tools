# Copyright (c) 2019, XMOS Ltd, All rights reserved

import pytest

from copy import deepcopy

from tflite2xcore.transformation_passes import ReplaceDeepConv2dPass

from tflite2xcore.tests.test_transformation_passes.model_builders import build_conv2d
from .conftest import (
    PARAMS,
    test_matching_params,
    test_non_matching_output_channels,
    test_non_matching_input_channels,
    test_non_matching_tensors
)


#  ----------------------------------------------------------------------------
#                              PARAMETER VALUES
#  ----------------------------------------------------------------------------

PARAMS = deepcopy(PARAMS)

PARAMS["extended"].update({
    "stride_h": [1, 2, 3],  # TODO: this should be the default after the conv2d improvements
    "stride_w": [1, 2, 3],  # TODO: this should be the default after the conv2d improvements
})

PARAMS["default"].update({
    "stride_h": [1, 2],  # TODO: this should be the default after the conv2d improvements
    "stride_w": [1, 2],  # TODO: this should be the default after the conv2d improvements
})

PARAMS["smoke"].update({
    "stride_h": [1],  # TODO: this should be the default after the conv2d improvements
    "stride_w": [1],  # TODO: this should be the default after the conv2d improvements
})


#  ----------------------------------------------------------------------------
#                                   FIXTURES
#  ----------------------------------------------------------------------------

@pytest.fixture()
def build_model():
    return build_conv2d


@pytest.fixture()
def trf_pass():
    return ReplaceDeepConv2dPass()


@pytest.fixture()
def model(weight_shape, input_size, padding, strides):
    return build_conv2d(weight_shape=weight_shape, input_size=input_size,
                        padding=padding, strides=strides)


if __name__ == "__main__":
    pytest.main()
