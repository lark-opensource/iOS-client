#ifndef _SMASH_SNAPSHOTAPI_H_
#define _SMASH_SNAPSHOTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE SnapShotHandle

typedef void* MODULE_HANDLE;

////     SnapShotRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
////     TODO: 根据实际情况修改
//    struct SnapShotRecommendConfig {
//        int InputWidth = 128;
//        int InputHeight = 224;
//    };
//
//    // 模型参数类型
//    // TODO: 根据实际情况修改
//    enum SnapShotParamType {
//        kSnapShotEdgeMode,
//    };
//
//    // 模型枚举，有些模块可能有多个模型
//    // TODO: 根据实际情况更改
//    enum SnapShotModelType {
//        kSnapShotModel1,
//    };

typedef struct {
  ModuleBaseArgs base;
  // 此处可以添加额外的算法参数
  unsigned char* mask;
  int mask_height;
  int mask_width;
  int target_height;
  int target_width;
} SnapShotArgs;

typedef struct {
  // TODO: 以下换成你自己的算法模块返回内容定义
  //        unsigned char* alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask
  //        预测值，值位于
  // [0, 255] 之间
  //        int width;
  //        int height;
  bool take_this;
} SnapShotRet;

// 创建句柄
AILAB_EXPORT int SnapShot_CreateHandle(void** out);

//    // 加载模型（从文件系统中加载）
//    AILAB_EXPORT int SnapShot_LoadModel(void* handle,
//                                        SnapShotModelType type,
//                                        const char* model_path);
//
//    // 加载模型（从内存中加载，Android 推荐使用该接口）
//    AILAB_EXPORT int SnapShot_LoadModelFromBuff(void* handle,
//                                                SnapShotModelType type,
//                                                const char* mem_model,
//                                                int model_size);
//
//    // 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用
//    #{MODULE}_DO
//    // 接口进行更换
AILAB_EXPORT int SnapShot_SetParamF(void* handle,
                                    int frame_interval,
                                    int frame_delay,
                                    int long_time_scale);
//
//    // 配置 char* 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO
//    // 接口进行更换
//    AILAB_EXPORT int SnapShot_SetParamS(void* handle,
//                                        SnapShotParamType type,
//                                        char* value);

// 算法主调用接口
AILAB_EXPORT int SnapShot_DO(void* handle,
                             SnapShotArgs* args,
                             SnapShotRet* ret);

// 销毁句柄
AILAB_EXPORT int SnapShot_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int SnapShot_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_SNAPSHOTAPI_H_
