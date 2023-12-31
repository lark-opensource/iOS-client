#ifndef _SMASH_EFFECTRECAPI_H_
#define _SMASH_EFFECTRECAPI_H_


#include "smash_module_tpl.h"

#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

#ifdef MODULE_HANDLE
#undef MODULE_HANDLE
#endif
#define MODULE_HANDLE EffectRecHandle

#define MAX_FACE_COUNT 10
#define MAX_REC_NUM 100
#define MAX_SCENE_COUNT 100
//#define MAX_FEATURE_LEN 100
typedef void* MODULE_HANDLE;

// EffectRecRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
// TODO: 根据实际情况修改

//特效及对应的特征信息； 特征信息从Lab 服务端获取
typedef struct EffectFeatureInfo {
  int effectId;          // 特效id
  float* effectFeature;  // 特效对应的特征信息，当前版本是 31 维
  int feature_dim; // 特效特征的长度
} EffectFeatureInfo;

typedef struct EffectFeatureInfoList {
  EffectFeatureInfo* features; // 特效信息列表
  int num_features;  // 特效数量
  unsigned int feature_version; // 版本号，当前是 0
} EffectFeatureInfoList;

typedef struct EffectRecResult {
  int effectId;   // 特效id
  float confidence; // 推荐置信度
} EffectRecResult;

// 人脸信息，依赖effect 透传，当前effect 尚不支持透传这些信息
typedef struct EffectRecFaceBaseInfo {
  float left;  // 人脸在图像中相对位置信息，0 ~ 1
  float top;  // 人脸在图像中相对位置信息，0 ~ 1
  float right; // 人脸在图像中相对位置信息，0 ~ 1
  float bottom; // 人脸在图像中相对位置信息，0 ~ 1
  float age;  // 人脸年龄信息
  float boy_prob; // 男性的概率
} EffectRecFaceBaseInfo;

// 人脸信息聚合
typedef struct EffectRecFaceInfo {
  EffectRecFaceBaseInfo base_infos[MAX_FACE_COUNT];
  int face_count; // 人脸个数
} EffectRecFaceInfo;

// 场景识别信息， 依赖effect 透传，当前版本可以获取
typedef struct SceneBaseInfo {
  float prob; // 场景概率
  bool satisfied; // 是否被分类为当前场景
} SceneBaseInfo;

// 场景信息聚合
typedef struct EffectRecSceneInfo {
  SceneBaseInfo base_infos[MAX_SCENE_COUNT];
  int scene_count;
} EffectRecSceneInfo;

// 算法返回结果
typedef struct EffectRecRet {
  // TODO: 以下换成你自己的算法模块返回内容定义
  EffectRecResult result[MAX_REC_NUM];
  int num_result;
} EffectRecRet;

// 创建句柄
AILAB_EXPORT int EffectRec_CreateHandle(void** out);

// 加载feature
AILAB_EXPORT int EffectRec_Init(void* handle, EffectFeatureInfoList features);

// 算法输入信息
typedef struct EffectRecArgs {
  EffectRecFaceInfo er_face_info;
  EffectRecSceneInfo er_scene_info;
  int topK_K;
} EffectRecArgs;

// 算法主调用接口
AILAB_EXPORT int EffectRec_DO(void* handle,
                              EffectRecArgs* args,
                              EffectRecRet* ret);


// 销毁句柄
AILAB_EXPORT int EffectRec_ReleaseHandle(void* handle);

// 打印该模块的参数，用于调试
AILAB_EXPORT int EffectRec_DbgPretty(void* handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif  // _SMASH_EFFECTRECAPI_H_
