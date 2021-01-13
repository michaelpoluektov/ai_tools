# Copyright (c) 2020, XMOS Ltd, All rights reserved

import pytest

pytestmark = pytest.mark.skip

import larq
import logging
import tensorflow as tf
import numpy as np
from pathlib import Path
from typing import Optional, Tuple, Any, Union
from tensorflow.python.keras.utils import data_utils

from tflite2xcore.utils import LoggingContext  # type: ignore # TODO: fix this
from tflite2xcore.xcore_schema import (  # type: ignore # TODO: fix this
    XCOREModel,
    XCOREOpCodes,
    BuiltinOpCodes,
    OperatorCode,
    TensorType,
)
from tflite2xcore.model_generation import Configuration
from tflite2xcore.model_generation.data_factories import TensorDataFactory

from . import IntegrationTestModelGenerator, BinarizedTestRunner

from . import (  # pylint: disable=unused-import
    test_idempotence,
    test_output,
)


#  ----------------------------------------------------------------------------
#                                   GENERATORS
#  ----------------------------------------------------------------------------


class BNNModelGenerator(IntegrationTestModelGenerator):
    def _build_core_model(self) -> tf.keras.Model:
        # tf may complain about missing gradients, so silence it
        with LoggingContext(tf.get_logger(), logging.ERROR):
            return tf.keras.models.load_model(
                Path(__file__).parent / "bnn_model", compile=False
            )


GENERATOR = BNNModelGenerator

#  ----------------------------------------------------------------------------
#                                DATA FACTORIES
#  ----------------------------------------------------------------------------


class CIFAR10DataFactory(TensorDataFactory):
    def make_data(self, batch: Optional[int] = None) -> tf.Tensor:
        (train_images, _), (test_images, _) = tf.keras.datasets.cifar10.load_data()
        return tf.cast(train_images - 128.0, tf.int8)[:batch]


#  ----------------------------------------------------------------------------
#                                   RUNNERS
#  ----------------------------------------------------------------------------


class CIFAR10BinarizedTestRunner(BinarizedTestRunner):
    def make_repr_data_factory(self) -> TensorDataFactory:
        return CIFAR10DataFactory(self, lambda: self._model_generator.input_shape)


RUNNER = CIFAR10BinarizedTestRunner


#  ----------------------------------------------------------------------------
#                                   CONFIGS
#  ----------------------------------------------------------------------------

# TODO: fix this
CONFIGS = {
    "default": {0: {}},
}


#  ----------------------------------------------------------------------------
#                                   FIXTURES
#  ----------------------------------------------------------------------------


@pytest.fixture  # type: ignore
def abs_output_tolerance() -> int:
    return 0


#  ----------------------------------------------------------------------------
#                                   TESTS
#  ----------------------------------------------------------------------------


# def test_converted_model(xcore_model: XCOREModel) -> None:
#     subgraph = xcore_model.subgraphs[0]

# # check tensors
# assert len(subgraph.tensors) == 90

# assert len(subgraph.inputs) == 1
# input_tensor = subgraph.inputs[0]
# assert input_tensor.type is TensorType.INT8
# input_shape = input_tensor.shape
# assert len(input_shape) == 4
# assert input_shape[0] == 1
# assert input_shape[3] == 3

# assert len(subgraph.outputs) == 1
# output_tensor = subgraph.outputs[0]
# assert output_tensor.type is TensorType.INT8
# assert output_tensor.shape == (1, 1000)

# # check operators
# assert len(subgraph.operators) == 31

# # check only first op
# assert len(input_tensor.consumers) == 1
# assert input_tensor.consumers[0].operator_code.code is BuiltinOpCodes.PAD

# opcode_cnt = xcore_model.count_operator_codes()
# assert opcode_cnt[OperatorCode(XCOREOpCodes.XC_conv2d_1x1)] == 13
# assert opcode_cnt[OperatorCode(XCOREOpCodes.XC_conv2d_depthwise)] == 13
# assert opcode_cnt[OperatorCode(BuiltinOpCodes.PAD)] == 1
# assert opcode_cnt[OperatorCode(XCOREOpCodes.XC_conv2d_shallowin)] == 1
# assert opcode_cnt[OperatorCode(XCOREOpCodes.XC_avgpool2d_global)] == 1
# assert opcode_cnt[OperatorCode(XCOREOpCodes.XC_fc)] == 1
# assert opcode_cnt[OperatorCode(BuiltinOpCodes.SOFTMAX, version=2)] == 1


if __name__ == "__main__":
    pytest.main()
