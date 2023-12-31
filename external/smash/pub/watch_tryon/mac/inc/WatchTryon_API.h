#ifndef _SMASH_WATCHTRYONAPI_H_
#define _SMASH_WATCHTRYONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

//this is only for debug
//#define SMASH_WATCH_TRYON_DEBUG

#define WATCH_TRYON_NUM_KEY_POINTS 48

// clang-format off
typedef void* WatchTryonHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum WatchTryonParamType {
  WATCH_TRYON_DETECT_FREQUENCE = 1001,        ///< TODO: 根据实际情况修改
  WATCH_TRYON_FILTER_FREQUENCE = 1002,
  WATCH_TRYON_FAST_MODE = 1003,

} WatchTryonParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum WatchTryonModelType {
  WATCH_TRYON_MODEL = 0x0001,       // 手腕模型，必须加载
} WatchTryonModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct WatchTryonArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  int left_right_mode; // 0 left 1 right 2 auto
  // 此处可以添加额外的算法参数
} WatchTryonArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
#ifdef SMASH_WATCH_TRYON_DEBUG
#define WATCH_TRYON_NUM_EDGE_POINTS 10
#define WATCH_TRYON_NUM_TRACKING_POINTS 50
#define WATCH_TRYON_OCCLUDER_NUM_POINTS 85
typedef struct WatchTryonInfo {
  float trans[12];
  float box[4]; //left, top, right, bottom
  float input_box[4]; //关键预测输入框
  float rotate[6]; //关键点预测align角度
  int is_motion_reliable;
  TTKeyPoint edge_points[WATCH_TRYON_NUM_EDGE_POINTS];
  TTKeyPoint extra_match_edge_points[4];
  TTKeyPoint fitting_project_points[WATCH_TRYON_OCCLUDER_NUM_POINTS];
  TTKeyPoint extra_project_points[4];
  float key_points[WATCH_TRYON_NUM_KEY_POINTS * 3];  // x, y, score
  float confidence;
  TTKeyPoint tracking_points[WATCH_TRYON_NUM_TRACKING_POINTS];
  float* vertices;
  int vertices_count;
  unsigned short* triangles;
  int triangles_count;
  int is_left;
} WatchTryonInfo;
#else
typedef struct WatchTryonInfo {
  float trans[12];
  float key_points[WATCH_TRYON_NUM_KEY_POINTS * 3];  // x, y, score
  float confidence;
  float* vertices;
  int vertices_count;
  unsigned short* triangles;
  int triangles_count;
  int is_left;
} WatchTryonInfo;
#endif

typedef struct WatchTryonRet {
  WatchTryonInfo p_watches[2];
  int watch_count;
} WatchTryonRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return WatchTryon_CreateHandle
 */
AILAB_EXPORT
int WatchTryon_CreateHandle(WatchTryonHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return WatchTryon_LoadModel
 */
AILAB_EXPORT
int WatchTryon_LoadModel(WatchTryonHandle handle,
                         WatchTryonModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return WatchTryon_LoadModelFromBuff
 */
AILAB_EXPORT
int WatchTryon_LoadModelFromBuff(WatchTryonHandle handle,
                                 WatchTryonModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return WatchTryon_SetParamF
 */
AILAB_EXPORT
int WatchTryon_SetParamF(WatchTryonHandle handle,
                         WatchTryonParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT WatchTryon_DO
 */
AILAB_EXPORT
int WatchTryon_DO(WatchTryonHandle handle,
                  WatchTryonArgs* args,
                  WatchTryonRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT WatchTryon_ReleaseHandle
 */
AILAB_EXPORT
int WatchTryon_ReleaseHandle(WatchTryonHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT WatchTryon_DbgPretty
 */
AILAB_EXPORT
int WatchTryon_DbgPretty(WatchTryonHandle handle);

/**
 * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
 *
 * @param width
 * @param height
 * @return AILAB_EXPORT WatchTryon_MallocResultMemory
 */
AILAB_EXPORT
WatchTryonRet* WatchTryon_MallocResultMemory(WatchTryonHandle handle);

/**
 * @brief 释放算法输出结构体空间
 *
 * @param ret
 * @return AILAB_EXPORT WatchTryon_FreeResultMemory
 */
AILAB_EXPORT
int WatchTryon_FreeResultMemory(WatchTryonRet* ret);

/**
 * @brief 清除句柄历史状态
 *
 * @param handle
 * @return AILAB_EXPORT WatchTryon_Reset
 */
AILAB_EXPORT
int WatchTryon_Reset(WatchTryonHandle handle);


////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_WATCHTRYONAPI_H_
