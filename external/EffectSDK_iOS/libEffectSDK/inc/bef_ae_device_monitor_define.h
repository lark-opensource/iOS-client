/**
 * @file bef_ae_device_monitor_define.h
 * @author liminghao (liminghao.o@bytedance.com)
 * @brief 
 * @version 0.1
 * @date 2022-07-28
 * 
 * @copyright Copyright (c) 2022
 * 
 */
#ifndef bef_ae_device_monitor_define_h
#define bef_ae_device_monitor_define_h

#include <stdint.h>

typedef struct bef_ae_gpu_info_st
{
    uint64_t m_vendor;
    uint8_t m_deviceIndex;
    //memory
    float m_gpuDedicatedMemoryUsage;
    float m_gpuSharedMemoryUsedUsage;
    float m_gpuDedicatedMemoryUsedSize;
    float m_gpuSharedMemoryUsedSize;
    //3D engin
    float m_gpu3DUsage;
    float m_gpuDecodeUsage;
    float m_gpuVPUsage;
    float m_gpuEncodeUsage;
    float m_gpuTotalUsage;
    bool m_isDiscreteGraphics;
} bef_ae_gpu_info;

typedef enum bef_ae_cpu_type_e
{
    X32, // Color filling
    X64, // Texture filling
} bef_ae_cpu_type;

typedef enum bef_ae_device_pressure_type_e
{
    NO_PRESSURE, //The threshold was not reached.
    SMALL,       //Initial threshold reached.
    MEDIUM,      //medium pressure.
    LARGE,       //large pressure.
    GRAVE,       //grave pressure.
} bef_ae_device_pressure_type;

typedef struct bef_ae_cpu_info_st
{
    int m_coreNumber;
    float m_useage;
    bef_ae_device_pressure_type m_level;
    double m_majorFrequency;
} bef_ae_cpu_info;

typedef struct bef_ae_mem_info_st
{
    uint64_t m_total;
    uint64_t m_used;
    uint64_t m_freed;
    bef_ae_device_pressure_type m_level;
} bef_ae_mem_info;

typedef struct bef_ae_disk_info_st
{
    uint64_t m_total;
    uint64_t m_used;
    uint64_t m_freed;
    bef_ae_device_pressure_type m_level;
} bef_ae_disk_info;

#endif