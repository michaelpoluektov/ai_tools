# Copyright (c) 2019, XMOS Ltd, All rights reserved

import struct

import numpy as np

from tflite2xcore_utils import generate_unique_tensor_name, XCOps
from tflite2xcore_utils import get_custom_opcode_index, tensor_to_np
from tflite2xcore_utils import get_input_tensor, get_buffer_data_of_tensor


def replace_basic_op(model, subgraph_ind, op_ind, opcode_str):
    subgraph = model['subgraphs'][subgraph_ind]
    custom_opcode_ind = get_custom_opcode_index(model, opcode_str)
    op = subgraph['operators'][op_ind]
    op['opcode_index'] = custom_opcode_ind
    op['builtin_options_type'] = 'NONE'
    del op['builtin_options']


def replace_with_XC_maxpool2d_deep(model, subgraph_ind, op_ind):
    opcode_str = XCOps.MAXPOOL2D_DEEP
    replace_basic_op(model, subgraph_ind, op_ind, opcode_str)


def calculate_real_multiplier(output_tensor, bias_tensor):
    output_scale = output_tensor['quantization']['scale'][0]
    bias_scale = np.array(bias_tensor['quantization']['scale'])
    return bias_scale / output_scale


def calculate_unified_bias(weights, bias, input_zero_point, output_zero_point, multiplier):
    zero_point_bias = np.sum(weights * input_zero_point,
                             axis=tuple(j for j in range(1, len(weights.shape))))
    return bias - np.int32(zero_point_bias) + np.int32(np.round(output_zero_point / multiplier))


def calculate_shift_scale(multiplier, bias_size):
    # NOTE: VLMUL expects one factor in Q2.14
    rshift = -np.ceil(np.log2(multiplier))
    scale = np.round(2**14 * (multiplier * 2**rshift))

    for j in range(len(scale)):
        if scale[j] == 2**14:
            rshift[j] -= 1
            scale[j] /= 2
        rshift[j] -= 7 # this is because we are using 15 bits instead of 8

    if len(scale) == 1:
        rshift = np.repeat(rshift, bias_size)
        scale = np.repeat(scale, bias_size)
    return np.int16(rshift), np.int16(scale)


def add_XC_shift_scale(model, subgraph_ind, multiplier, op, opcode_str, bias_size):
    subgraph = model['subgraphs'][subgraph_ind]

    # quantize multiplier and get right shift/scale
    rshift, scale = calculate_shift_scale(multiplier, bias_size)

    # add tensor and buffer for rshift
    op['inputs'].append(len(subgraph['tensors']))
    subgraph['tensors'].append({
        'shape': list(rshift.shape),
        'type': 'INT16',
        'buffer': len(model['buffers']),
        'name': generate_unique_tensor_name(subgraph, base_name=opcode_str, suffix='/rshift'),
        'is_variable': False
    })
    model['buffers'].append({
        'data': list(b''.join([struct.pack('h', a) for a in rshift]))  # pylint: disable=not-an-iterable
    })

    # add tensor and buffer for scale
    op['inputs'].append(len(subgraph['tensors']))
    subgraph['tensors'].append({
        'shape': list(scale.shape),
        'type': 'INT16',
        'buffer': len(model['buffers']),
        'name': generate_unique_tensor_name(subgraph, base_name=opcode_str, suffix='/scale'),
        'is_variable': False
    })
    model['buffers'].append({
        'data': list(b''.join([struct.pack('h', a) for a in scale]))  # pylint: disable=not-an-iterable
    })


def replace_with_XC_fc_deepin_shallowout_final(model, subgraph_ind, op_ind):
    opcode_str = XCOps.FC_DEEPIN_SHALLOWOUT_FINAL
    replace_basic_op(model, subgraph_ind, op_ind, opcode_str)

    subgraph = model['subgraphs'][subgraph_ind]
    op = subgraph['operators'][op_ind]

    # retrieve weights, and rename weight tensor
    weight_tensor = get_input_tensor(subgraph, op_ind, input_ind=1)
    weights = tensor_to_np(model, weight_tensor)

    # retrieve biases
    bias_tensor = get_input_tensor(subgraph, op_ind, input_ind=2)
    bias = tensor_to_np(model, bias_tensor)

    # retrieve input zero point
    input_tensor = get_input_tensor(subgraph, op_ind, input_ind=0)
    input_zero_point = np.int32(input_tensor['quantization']['zero_point'][0])

    # retreive output quantization
    output_tensor = subgraph['tensors'][op['outputs'][0]]
    output_zero_point = output_tensor['quantization']['zero_point'][0]

    # calculate real multiplier
    multiplier = calculate_real_multiplier(output_tensor, bias_tensor)

    # calculate and save a unified bias vector
    bias = calculate_unified_bias(weights, bias, input_zero_point, output_zero_point, multiplier)
    buffer_ind = bias_tensor['buffer']
    model['buffers'][buffer_ind]['data'] = list(bias.tostring())

    # rename bias tensor
    bias_tensor['name'] = generate_unique_tensor_name(subgraph,
        base_name=opcode_str, suffix='/biases')

    # rename weight tensor
    # NOTE: no weight layout rearrangement is done for this op
    weight_tensor['name'] = generate_unique_tensor_name(subgraph,
        base_name=opcode_str, suffix='/weights')

    # rename output tensor, change type and quantization
    # NOTE: this is because the op is at the end of a network, and should be followed by argmax/softmax
    output_tensor['type'] = 'INT16'
    output_tensor['name'] = generate_unique_tensor_name(subgraph,
        base_name=opcode_str, suffix='/output')
    output_tensor['quantization'] = {
        'scale': [output_tensor['quantization']['scale'][0] / 2**7],
        'zero_point': [int(output_tensor['quantization']['zero_point'][0] * 2**7)],
        'details_type': "CustomQuantization",
        'quantized_dimension': 0
    }

    add_XC_shift_scale(model, subgraph_ind, multiplier, op, opcode_str, bias.size)
    


def replace_with_XC_conv2d_deepin_deepout_relu(model, subgraph_ind, op_ind):
    opcode_str = XCOps.CONV2D_DEEPIN_DEEPOUT_RELU
    replace_basic_op(model, subgraph_ind, op_ind, opcode_str)

    subgraph = model['subgraphs'][subgraph_ind]
    op = subgraph['operators'][op_ind]

    # retrieve weights, and rename weight tensor
    weight_tensor = get_input_tensor(subgraph, op_ind, input_ind=1)
    weights = tensor_to_np(model, weight_tensor)

    # retrieve biases
    bias_tensor = get_input_tensor(subgraph, op_ind, input_ind=2)
    bias = tensor_to_np(model, bias_tensor)

    # retrieve input zero point
    input_tensor = get_input_tensor(subgraph, op_ind, input_ind=0)
    input_zero_point = np.int32(input_tensor['quantization']['zero_point'][0])

    # retreive output quantization
    output_tensor = subgraph['tensors'][op['outputs'][0]]
    output_zero_point = output_tensor['quantization']['zero_point'][0]

    # calculate real multiplier
    multiplier = calculate_real_multiplier(output_tensor, bias_tensor)

    # calculate a unified bias vector and rearrange
    bias = calculate_unified_bias(weights, bias,
                                  input_zero_point, output_zero_point, multiplier)
    new_bias = np.uint8(list(bias.tostring())).reshape((-1, 4))
    new_bias = np.vstack([new_bias[:,:2], new_bias[:,2:]]).flatten()

    # save bias vector data, change type and shape
    buffer_ind = bias_tensor['buffer']
    bias_tensor['type'] = 'INT16'
    bias_tensor['shape'] = [2] + bias_tensor['shape']
    model['buffers'][buffer_ind]['data'] = list(new_bias.tostring())

    # rename bias tensor
    bias_tensor['name'] = generate_unique_tensor_name(subgraph,
        base_name=opcode_str, suffix='/biases')

    # rearrange weight tensor
    acc_period = 16
    weights = [np.flip(weights[j:j+acc_period, :, :, :], axis=0)
               for j in range(0, weights.shape[0], acc_period)]
    weights = np.int8(np.vstack(weights))

    # save weight tensor
    buffer_ind = weight_tensor['buffer']
    model['buffers'][buffer_ind]['data'] = list(weights.tostring())

    # rename weight tensor
    weight_tensor['name'] = generate_unique_tensor_name(subgraph,
        base_name=opcode_str, suffix='/weights')

    add_XC_shift_scale(model, subgraph_ind, multiplier, op, opcode_str, bias.size)