# Copyright (c) 2020, XMOS Ltd, All rights reserved

import pytest
import tensorflow as tf
from typing import Callable

from tflite2xcore.xcore_schema import BuiltinOpCodes  # type: ignore # TODO: fix this

from . import LUTActivationOpTestModelGenerator
from . import (  # pylint: disable=unused-import
    test_output,
    test_converted_single_op_model,
    test_reference_model_regression,
)


#  ----------------------------------------------------------------------------
#                                   GENERATORS
#  ----------------------------------------------------------------------------


class ReluTestModelGenerator(LUTActivationOpTestModelGenerator):
    @property
    def act_fun(self) -> Callable[[tf.Tensor], tf.Tensor]:
        return lambda x: tf.nn.relu(x)


GENERATOR = ReluTestModelGenerator

#  ----------------------------------------------------------------------------
#                                   FIXTURES
#  ----------------------------------------------------------------------------


@pytest.fixture  # type: ignore
def reference_op_code() -> BuiltinOpCodes:
    return BuiltinOpCodes.RELU


if __name__ == "__main__":
    pytest.main()