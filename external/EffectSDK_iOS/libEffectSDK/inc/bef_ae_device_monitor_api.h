/**
 * @file bef_ae_device_monitor_api.h
 * @author liminghao (liminghao.o@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2022-07-28
 * 
 * @copyright Copyright (c) 2022
 * 
 */

#ifndef bef_ae_device_monitor_api_h
#define bef_ae_device_monitor_api_h

#pragma once
#include "bef_framework_public_base_define.h"
#include "bef_ae_device_monitor_define.h"
/**
 * @brief update all device info
 * 
 * @param cpuInfo 
 * @param gpuInfo 
 * @param memInfo 
 * @param diskInfo 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_ae_device_update_all_info(bef_ae_cpu_info* cpuInfo,
                                                              bef_ae_gpu_info* gpuInfo,
                                                              bef_ae_mem_info* memInfo,
                                                              bef_ae_disk_info* diskInfo);
/**
 * @brief update cpu info
 * 
 * @param cpuInfo 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_ae_device_update_cpu_info(bef_ae_cpu_info* cpuInfo);

/**
 * @brief update gpu info
 * 
 * @param gpuInfo 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_ae_device_update_gpu_info(bef_ae_gpu_info* gpuInfo);

/**
 * @brief update memory info
 * 
 * @param memInfo 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_ae_device_update_mem_info(bef_ae_mem_info* memInfo);

/**
 * @brief update disk info
 * 
 * @param diskInfo 
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_ae_device_update_disk_info(bef_ae_disk_info* diskInfo);

#endif