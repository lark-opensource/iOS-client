//
//  bef_benchmark_api.h
//  Pods
//
//  Created by bytedance on 2019/5/7.
//

#ifndef bef_benchmark_api_h
#define bef_benchmark_api_h

#include "bef_effect_public_define.h"

/// Only supports three-channel images(rgb bgr)
BEF_SDK_API bef_bench_ret bef_effect_bench_gaussianBlur(bef_bench_input_param input_param);

/// Only grayscale image is supported(gray)
BEF_SDK_API bef_bench_ret bef_effect_bench_equalizeHist(bef_bench_input_param input_param);

#endif /* bef_benchmark_api_h */
