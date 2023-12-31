//
// live volume detection class and interface.
// self explained
// written by will.li in 20th.Dec.2018
//

#ifndef VE_VOLUMEDETECTION_H
#define VE_VOLUMEDETECTION_H

#include <cstdint>
#include <utility>
#include <vector>
#include "ae_defs.h"

class VolumeDetectionObj;
using VDPointer = VolumeDetectionObj*;

/*
 * 初始化一个VolumeDetectionObj*实例
 * VDPtr:       VDPointer 变量的引用
 * sampleRate:  pcm码流的采样率，初始化之后在Process阶段就以该采样率解析pcm流、
 * Return:      0：初始化成功；negative：初始化失败
 */
MAMMON_EXPORT int16_t Init_VolumeInst(VDPointer& VDPtr, const int32_t sampleRate);

/*
 * 顺序读入一段pcm流，每隔20ms输出当前的volume值
 * VDPtr：               已经初始化的VDPointer 变量的引用
 * f_pcmFlow：           以float格式保存的pcm流地址
 * pcm_size：            pcm流的长度
 * onsetIndexVecInTime： 检测到的onset时间点，以秒为单位
 * Return：              1 代表没有Volume值输出，需要继续继续调用Process_VolumeInst直到返回0
 *                       0
 * 代表检测到onset，需要及时处理onsetIndexVecInTime，每次调用Process_OnsetInst都会刷新onsetIndexVecInTime negative
 * 代表出错
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const float* f_pcmFlow, const size_t pcm_size,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * 以vector<float> 参数重载 Process_VolumeInst 接口
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const std::vector<float>& f_pcmVec,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * const double* 调用pcm流，内部重载const float*接口
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const double* d_pcmFlowc, const size_t pcm_size,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * vector<double> 调用pcm流，内部重载const double*接口
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const std::vector<double>& d_pcmVec,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * const int16_t* 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const int16_t* int_pcmFlow, const size_t pcm_size,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * vector<int16_t> 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const std::vector<int16_t>& int_pcmVec,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 *
 */
MAMMON_EXPORT int16_t Process_VolumeInst(VDPointer& VDPtr, const float** f_2ch_pcmFlow, const size_t pcm_size,
                           std::vector<std::pair<float, float>>& VolumeSeqPair);

/*
 * 释放 VDPointer 指向资源的内部状态，相当于 Init_VolumeInst 之后的 VolumeDetectionObj 对象
 * VDPtr    已经初始化的 VDPointer 引用
 * Return   0 Reset成功；negative Reset失败
 */
MAMMON_EXPORT int16_t Reset_VolumeInst(VDPointer& VDPtr);

/*
 * 释放 VDPtr 的资源，置 VDPtr 为空指针
 * VDPtr：   已经初始化的 VDPointer 引用
 * Return：  0：成功；negative：失败，一般原因是ODPtr 传入即为null
 */
MAMMON_EXPORT int16_t Destroy_VolumeInst(VDPointer& VDPtr);

#endif  // VE_VOLUMEDETECTION_H
