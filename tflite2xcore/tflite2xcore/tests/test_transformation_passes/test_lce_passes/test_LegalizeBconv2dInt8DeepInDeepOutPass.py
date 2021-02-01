# Copyright (c) 2020, XMOS Ltd, All rights reserved
import pytest

from tflite2xcore.transformation_passes import (
    LegalizeBconv2dInt8DeepInDeepOutPass,
    ReplaceBconv2DInt8DeepInDeepOutPass,
)
from tflite2xcore.xcore_schema import XCOREModel, XCOREOpCodes

from .test_LegalizeBconv2dInt8Pass import _test_mutate
from .test_ReplaceBconv2DInt8DeepInDeepOutPass import (  # pylint: disable=unused-import
    model,
    new_opcode,
    PARAMS,
)


#  ----------------------------------------------------------------------------
#                                   FIXTURES
#  ----------------------------------------------------------------------------


@pytest.fixture()  # type: ignore
def replacement_pass() -> ReplaceBconv2DInt8DeepInDeepOutPass:
    return ReplaceBconv2DInt8DeepInDeepOutPass()


@pytest.fixture()  # type: ignore
def legalization_pass() -> LegalizeBconv2dInt8DeepInDeepOutPass:
    return LegalizeBconv2dInt8DeepInDeepOutPass()


#  ----------------------------------------------------------------------------
#                                   TESTS
#  ----------------------------------------------------------------------------


def test_mutate(
    replacement_pass: ReplaceBconv2DInt8DeepInDeepOutPass,
    legalization_pass: LegalizeBconv2dInt8DeepInDeepOutPass,
    model: XCOREModel,
    new_opcode: XCOREOpCodes,
) -> None:
    _test_mutate(replacement_pass, legalization_pass, model, new_opcode)

    bconv2d_op = model.subgraphs[0].operators[0]
    assert len(bconv2d_op.inputs) == 4


if __name__ == "__main__":
    pytest.main()