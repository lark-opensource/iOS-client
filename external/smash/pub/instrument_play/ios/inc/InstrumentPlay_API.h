#ifndef _SMASH_INSTRUMENTPLAY_API_H_
#define _SMASH_INSTRUMENTPLAY_API_H_

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif
#define NUM_KEY_POINT 18

typedef enum {
  //动作类型
  UnknownAction = 0,
  Hand_LDL = 1,  //左手向下运动，并且停止位置在画面左侧
  Hand_LDR = 2,  //左手向下运动，并且停止位置在画面右侧
  Hand_LUL = 3,  //左手向上运动，并且停止位置在画面左侧
  Hand_LUR = 4,

  Hand_RDL = 5,
  Hand_RDR = 6,
  Hand_RUL = 7,
  Hand_RUR = 8,

} ActionType;

typedef struct {
  //输出动作和音乐指令
  int action_id;  //动作类型
  int audio_id;   //音乐编号
  int gap_time;   //停顿时间,目前没用
} ActionAudioItem;

typedef struct {
  ActionAudioItem *items;
  int item_len;  //动作和音乐指令个数
} InstrumentConfig;

typedef struct {
  ActionType *action_ids;
  int action_len;
} ActionResult;

typedef struct {
  int *audio_ids;
  int audio_len;
} AudioResult;

typedef struct {
  TTKeyPoint keypoints[NUM_KEY_POINT];
} InstrumentInput;

typedef enum {
  TimeStamp = 1,  //程序运行时间起点

  Drum_LowBeatLine = 102,    //底处水平碰撞检测线
  Drum_LeftSplit = 103,      //左侧数值碰撞检测线
  Drum_RightSplit = 104,     //由侧数值碰撞检测线
  Drum_DamplingThres = 105,  //防抖动阈值
  Drum_HighBeatLine = 106,   //高处水平碰撞检测线
  Drum_MiddleSplit = 107,    //中间水平碰撞检测线

} InstrumentParamType;

typedef void *InstrumentPlayHandle;

AILAB_EXPORT
int Instrument_CreateHandle(InstrumentPlayHandle *handle);

AILAB_EXPORT
int Instrument_SetParam(InstrumentPlayHandle handle,
                        InstrumentParamType type,
                        float value);
AILAB_EXPORT
int Instrument_SetConfig(InstrumentPlayHandle handle, InstrumentConfig *config);

// clang-format off
// Args:
//   handle: 创建的句柄
//   keypoints: 检测出的多人人体关键点
// Return:
//   action_ret: 返回值，内存由API里分配和释放
// clang-format on
AILAB_EXPORT
int Instrument_UpdateInstruct(InstrumentPlayHandle handle,
                              InstrumentInput *args,
                              ActionResult *action_ret);

// clang-format off
//游戏开始前,检测用户的姿态是否满足要求
// Args:
//   handle: 创建的句柄
//   keypoints: 检测出的多人人体关键点
// Return:
//   action_ret: 返回值，内存由API里分配和释放
// clang-format on
AILAB_EXPORT
int Instrument_CheckPosition(InstrumentPlayHandle handle,
                             InstrumentInput *args,
                             bool *in_position);

//获取当前需要播放的音乐指令
AILAB_EXPORT
int Instrument_GetPlayInstruct(InstrumentPlayHandle handle,
                               AudioResult *audio_ret);

AILAB_EXPORT
int Instrument_Release(InstrumentPlayHandle handle);

#if defined __cplusplus
};
#endif
#endif  // _SMASH_INSTRUMENTPLAY_API_H_
