
#include <float.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>

//TODO pass the clamps
void pick_post_activation_values(float * post_activation_multiplier, float * post_activation_bias, 
  unsigned chans_out, unsigned receptive_volume, int seed){

/*
  std::int8_t Run(const std::int32_t accum, int out_channel) const {
    // Clamping is done in int32
    std::int32_t x = accum << 1;
    x = std::max<std::int32_t>(std::min<std::int32_t>(x, clamp_max), clamp_min);
    // The linear transformation is done in float
    float y =
        static_cast<float>(x) * multiplier[out_channel] + bias[out_channel];
    // And then we round back to int32 and clamp to the int8 range
    return saturate(round(y));
  }
*/
  srand(seed);

  //The input range is from 0 to the receptive_volume (xor_popcount)
  float accu_min = 0; 
  float accu_max = receptive_volume*2; //the times 2 is due to the left shift in the output transform. 

  float input_range = accu_max - accu_min;

  float output_min = (float)INT8_MIN; 
  float output_max = (float)INT8_MAX; 

  for (unsigned ch = 0; ch < chans_out; ch++){

    unsigned range = rand()%receptive_volume;

    // Scale the input to extend beyond the range of the output such that we get some 
    // outputs that will saturate.
    float output_overscale = 0.5 + (float)rand()/(float)RAND_MAX;

    float output_range = (output_max - output_min)*output_overscale;

    // This offset allows the output range to completly miss the int8 output range sometimes
    float offset = 1.1 * output_range * (float)rand()/(float)RAND_MAX;

    post_activation_multiplier[ch] = output_range / input_range;
    post_activation_bias[ch] = output_min*output_overscale - accu_min* output_range / input_range + offset;
  }
}
