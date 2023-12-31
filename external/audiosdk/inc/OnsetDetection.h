//
// 集成VESDK的onset detection头文件
// self explained
// written by will.li in 17th.Dec.2018
//

#ifndef VE_ONSETDETECTION_H
#define VE_ONSETDETECTION_H

#include <cstdint>
#include <utility>
#include <vector>
#include <cstddef>
#include "ae_defs.h"

constexpr float CPX_THRESHOLD = 50.0f;

class OnsetDetectionObj;
using ODPointer = OnsetDetectionObj*;

/*
 * 初始化一个ODPtr实例，注意实际传入的参数是 OnsetDetectionObj**
 * ODPtr:       ODPointer 变量的引用
 * sampleRate:  pcm码流的采样率，初始化之后在Process阶段就以该采样率解析pcm流、
 * threshold:   onset检测的阈值，默认是500，需要密集检测降低阈值，稀疏检测提升阈值
 * Return:      0：初始化成功；negative：初始化失败
 */
MAMMON_EXPORT int16_t Init_OnsetInst(ODPointer& ODPtr, const int32_t sampleRate, const float threshold = CPX_THRESHOLD);

/*
 * 顺序读入一段pcm流，将检测到的onset时间点存储到onsetIndexVecInTime中
 * ODPtr：               已经初始化的ODPointer 变量的引用
 * f_pcmFlow：           以float格式保存的pcm流地址, ** 只支持单声道 **
 * pcm_size：            pcm流的长度，sample的个数，而不是数据流的长度（sample的个数乘以每个sample的位长 = 数据流长度）
 * onsetIndexPairInTime 检测到的(onset时间点，onset强度)组合，时间点以秒为单位
 * Return：              1 代表buffer没有被填满，需要继续继续调用Process_OnsetInst直到返回0
 *                       0
 * 代表检测到onset，需要及时处理onsetIndexVecInTime，每次调用Process_OnsetInst都会刷新onsetIndexVecInTime negative
 * 代表出错
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const float* f_pcmFlow, const size_t pcm_size,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 * 以vector<float> 参数重载Process_OnsetInst接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<float>& f_pcmVec,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 * const double* 调用pcm流，内部重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const double* d_pcmFlowc, const size_t pcm_size,
                          std::vector<std::pair<float, float>>& onsetIndexVecInTime);

/*
 * vector<double> 调用pcm流，内部重载const double*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<double>& d_pcmVec,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 * const int16_t* 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const int16_t* int_pcmFlow, const size_t pcm_size,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 * vector<int16_t> 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<int16_t>& int_pcmVec,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 *适配传增和effect郑微同学一起定义的接口
 *const float**f_2ch_pcmFlow 代表两个channel
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const float** f_2ch_pcmFlow, const size_t pcm_size,
                          std::vector<std::pair<float, float>>& onsetIndexPairInTime);

/*
 * 释放ODPointer指向资源的内部状态，相当于Init_OnsetInst之后的OnsetDetectionObj对象
 * ODPtr    已经初始化的ODPointer引用
 * Return   0 Reset成功；negative Reset失败
 */
MAMMON_EXPORT int16_t Reset_OnsetInst(ODPointer& ODPtr);

/*
 * 释放ODPtr的资源，置ODPtr 为空指针
 * ODPtr：   已经初始化的ODPointer引用
 * Return：  0：成功；negative：失败，一般原因是ODPtr 传入即为null
 */
MAMMON_EXPORT int16_t Destroy_OnsetInst(ODPointer& ODPtr);

/**
 * 兼容旧版本
 */

MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const float* f_pcmFlow, const size_t pcm_size,
                          std::vector<float>& onsetIndexInTime);

/*
 * 以vector<float> 参数重载Process_OnsetInst接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<float>& f_pcmVec, std::vector<float>& onsetIndexInTime);

/*
 * const double* 调用pcm流，内部重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const double* d_pcmFlowc, const size_t pcm_size,
                          std::vector<float>& onsetIndexInTime);

/*
 * vector<double> 调用pcm流，内部重载const double*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<double>& d_pcmVec, std::vector<float>& onsetIndexInTime);

/*
 * const int16_t* 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const int16_t* int_pcmFlow, const size_t pcm_size,
                          std::vector<float>& onsetIndexInTime);

/*
 * vector<int16_t> 调用16位整形pcm流，重载const float*接口
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const std::vector<int16_t>& int_pcmVec,
                          std::vector<float>& onsetIndexInTime);

/*
 *适配传增和effect郑微同学一起定义的接口
 *const float**f_2ch_pcmFlow 代表两个channel
 */
MAMMON_EXPORT int16_t Process_OnsetInst(ODPointer& ODPtr, const float** f_2ch_pcmFlow, const size_t pcm_size,
                          std::vector<float>& onsetIndexInTime);

#endif  // GIST_VEDEMO_ONSETDETECTION_H
