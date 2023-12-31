//
// Created by will_li on 2019-04-12.
//

#ifndef VE_F0DETECTION_H
#define VE_F0DETECTION_H

#include <cstdint>
#include <utility>
#include <vector>
#include "ae_defs.h"

class F0DetectionObj;
using F0DPointer = F0DetectionObj*;

/*
 * 初始化一个F0DetectionObj*实例
 * FDPtr:       F0DPointer 变量的引用
 * sampleRate:  pcm码流的采样率，初始化之后在Process阶段就以该采样率解析pcm流、
 * f0_min:      f0的下界
 * f0_max:      f0的上界
 * Return:      0：初始化成功；negative：初始化失败
 */
MAMMON_EXPORT int16_t Init_F0Inst(F0DPointer& FDPtr, const int32_t sampleRate, const float f0_min = 40.0f,
                    const float f0_max = 650.0f);

/*
 * 顺序读入一段pcm流，每隔20ms输出当前的f0值
 * FDPtr：               已经初始化的F0DPointer 变量的引用
 * f_pcmFlow：           以float格式保存的pcm流地址
 * pcm_size：            pcm流的长度
 * F0SeqPair：           检测到的pair(f0时间点, f0的取值)，以秒为单位
 * Return：              1 代表没有f0值输出，需要继续继续调用Process_F0Inst直到返回0
 *                       0 代表检测到f0，需要及时处理F0SeqPair，每次调用Process_F0Inst都会刷新F0SeqPair
 *                       negative 代表出错
 */
MAMMON_EXPORT int16_t Process_F0Inst(F0DPointer& FDPtr, const float* f_pcmFlow, const size_t pcm_size,
                       std::vector<std::pair<float, float>>& F0SeqPair);

/*
 * 以vector<float> 参数重载 Process_F0Inst 接口
 */
MAMMON_EXPORT int16_t Process_F0Inst(F0DPointer& FDPtr, const std::vector<float>& f_pcmVec,
                       std::vector<std::pair<float, float>>& F0SeqPair);

/*
 * const int16_t* 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_F0Inst(F0DPointer& FDPtr, const int16_t* int_pcmFlow, const size_t pcm_size,
                       std::vector<std::pair<float, float>>& F0SeqPair);

/*
 * vector<int16_t> 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_F0Inst(F0DPointer& FDPtr, const std::vector<int16_t>& int_pcmVec,
                       std::vector<std::pair<float, float>>& F0SeqPair);

/*
 *
 */
MAMMON_EXPORT int16_t Process_F0Inst(F0DPointer& FDPtr, const float** f_2ch_pcmFlow, const size_t pcm_size,
                       std::vector<std::pair<float, float>>& F0SeqPair);

/*
 * 释放 F0DPointer 指向资源的内部状态，相当于 Init_F0Inst 之后的 F0DetectionObj 对象
 * FDPtr    已经初始化的 F0DPointer 引用
 * Return   0 Reset成功；negative Reset失败
 */
MAMMON_EXPORT int16_t Reset_F0Inst(F0DPointer& FDPtr);

/*
 * 释放 VDPtr 的资源，置 VDPtr 为空指针
 * VDPtr：   已经初始化的 VDPointer 引用
 * Return：  0：成功；negative：失败，一般原因是ODPtr 传入即为null
 */
MAMMON_EXPORT int16_t Destroy_F0Inst(F0DPointer& FDPtr);

/*
 * 获取F0DPointer实例基f0最大最小值
 * FDPtr:   已经初始化的 VDPointer 引用
 * min_f0:  获取VDPointer实例基频下界
 * Return:  0：成功；negative：失败，一般原因是ODPtr 传入即为null
 */
MAMMON_EXPORT int16_t Get_f0_min_max(F0DPointer& FDPtr, float& min_f0, float& max_f0);

#endif  // VE_F0DETECTION_H
