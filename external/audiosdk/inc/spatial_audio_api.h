/* -*- c-basic-offset: 4 indent-tabs-mode: nil -*-  vi:set ts=8 sts=4 sw=4: */

/* Audio Effect Library */

/// spatial audio

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

//距离衰减模型
typedef enum {
    kNone = 0,
    kLogarithmic,  //声音随距离对数衰减
    kLinear,       //声音随距离线性衰减
    kInvalid,
} DistanceRolloffMode;

// 空间三维坐标定义
typedef struct {
    float x;
    float y;
    float z;
} WorldPosition;

// 声源定义
typedef struct {
    float source_gain;               // 音源增益：音源输入增益，默认1.0f
    float distance_attenuation_old;  //
    float distance_attenuation_new;  //
    float min_distance;              // 最小距离：小于此距离音量为1，默认为1.0f
    float max_distance;              // 最大距离：大于此距离音量为0
    float rolloff_factor;  // 衰减系数[0, 10.0f]：只对kLogarithmic模式有效; 增大rolloff_factor加快声音衰减
    WorldPosition position;                     // 音源坐标 (x,y,z)
    DistanceRolloffMode distance_rolloff_mode;  // 衰减模式：声音随距离的衰减模式
} SourceNode;

// 听者定义
typedef struct {
    WorldPosition position;  // 听者坐标 (x,y,z)
} ListenerNode;

// 初始化音源和听者
void initSource(SourceNode* source);
void initListener(ListenerNode* listener);

// 设置音源相关属性，主要是距离衰减模型(DistanceRolloffMode)，最大/最小距离，衰减系数
void setSourceGain(SourceNode* source, const float source_gain);
void setSourceRolloffMode(SourceNode* source, const DistanceRolloffMode distance_rolloff_mode);
void setSourceMinDis(SourceNode* source, const float min_distance);
void setSourceMaxDis(SourceNode* source, const float max_distance);
void setSourceRolloffFactor(SourceNode* source, const float rolloff_factor);

// 更新声源和听着的位置，建议每帧更新一次
void updateSourcePos(SourceNode* source, const WorldPosition position);
void updateListenerPos(ListenerNode* listener, const WorldPosition position);

// 计算并更新声源与听者之间的距离衰减值，建议每帧更新一次
void UpdateDistanceAttenuation(ListenerNode* listener, SourceNode* source);

// 对输入音频信号进行距离衰减处理，支持双声道输入，双声道输出
void sourceProcess(int processLength, SourceNode* source, const float* inputL, const float* inputR, float* outputL,
                   float* outputR);

#ifdef __cplusplus
}
#endif
