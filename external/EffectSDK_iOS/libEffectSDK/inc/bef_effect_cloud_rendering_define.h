//
//  bef_effect_cloud_rendering_define.h
//  effect_sdk
//
//  Created by TangQiuhu on 2021/3/5.
//

#ifndef bef_effect_cloud_rendering_define_h
#define bef_effect_cloud_rendering_define_h

typedef struct bef_cloud_rendering_extended_input_data
{
    
} bef_cloud_rendering_extended_input_data;

typedef struct bef_cloud_rendering_extended_output_data
{
    bool isCloud;
    double timestamp;
    unsigned int repeatCount;
} bef_cloud_rendering_extended_output_data;

#endif /* bef_effect_cloud_rendering_define_h */
