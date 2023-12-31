#ifndef _SMASH_AVACAP_API_H_
#define _SMASH_AVACAP_API_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void* avacapHandle;
#define AVACAP_MAX_FACERET 5
#define AVACAP_ID_LEN 75
#define AVACAP_EXPR_LEN 51
#define AVACAP_VER_LEN 1220
#define AVACAP_FACE_LEN 2304

  
#define AVACAP_PI 3.14159265359
  
#define AVACAP_eyeLookDown_L 0
#define AVACAP_noseSneer_L 1
#define AVACAP_eyeLookIn_L 2
#define AVACAP_browInnerUp 3
#define AVACAP_browDown_L 25
#define AVACAP_mouthClose 5
#define AVACAP_mouthLowerDown_R 6
#define AVACAP_jawOpen 7
#define AVACAP_mouthLowerDown_L 9
#define AVACAP_mouthFunnel 10
#define AVACAP_eyeLookIn_R 11
#define AVACAP_eyeLookDown_R 12
#define AVACAP_noseSneer_R 13
#define AVACAP_mouthRollUpper 14
#define AVACAP_jawRight 15
#define AVACAP_mouthDimple_L 16
#define AVACAP_mouthRollLower 17
#define AVACAP_mouthSmile_L 18
#define AVACAP_mouthPress_L 19
#define AVACAP_mouthSmile_R 20
#define AVACAP_mouthPress_R 21
#define AVACAP_mouthDimple_R 22
#define AVACAP_mouthLeft 23
#define AVACAP_eyeSquint_R 41
#define AVACAP_eyeSquint_L 4
#define AVACAP_mouthFrown_L 26
#define AVACAP_eyeBlink_L 27
#define AVACAP_cheekSquint_L 28
#define AVACAP_browOuterUp_L 29
#define AVACAP_eyeLookUp_L 30
#define AVACAP_jawLeft 31
#define AVACAP_mouthStretch_L 32
#define AVACAP_mouthStretch_R 33
#define AVACAP_mouthPucker 34
#define AVACAP_eyeLookUp_R 35
#define AVACAP_browOuterUp_R 36
#define AVACAP_cheekSquint_R 37
#define AVACAP_eyeBlink_R 38
#define AVACAP_mouthUpperUp_L 39
#define AVACAP_mouthFrown_R 40
#define AVACAP_browDown_R 24
#define AVACAP_jawForward 42
#define AVACAP_mouthUpperUp_R 43
#define AVACAP_cheekPuff 44
#define AVACAP_eyeLookOut_L 45
#define AVACAP_eyeLookOut_R 46
#define AVACAP_eyeWide_R 47
#define AVACAP_eyeWide_L 49
#define AVACAP_mouthRight 48
#define AVACAP_mouthShrugLower 8
#define AVACAP_mouthShrugUpper 50
#define AVACAP_tongueOut 51

  
/**
 * @brief 模型参数类型
 *
 */
typedef enum avacapParamType {
  kavacapCropSize = 1,        ///< TODO: 根据实际情况修改
  kavacapEnlarge = 2,
  kavacapSMWindow = 3,
  kavacapUMom = 4,
  kavacapDoPostEnhanceE = 5,
  kavacapDoPostSmoothE = 6,
  kavacapDoPostSmoothRT = 7,
  kavacapXC0 = 8,
  kavacapXC1 = 9,
  kavacapSmoothE = 10,
  kavacapSmoothR = 11,
  kavacapSmoothT = 12,
  kavacapEXC0 = 13,
  kavacapEXC1 = 14,
  kavacapSmoothTZ = 15,
  kavacapMaxZDiff = 16,
  kavacapSmoothET = 17
} avacapParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum avacapModelType {
  kavacapModel1 = 1,          ///< TODO: 根据实际情况更改
} avacapModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct avacapArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
  int use_smoother;
  int use_fitter;
  int build_mesh;
  int face_count;
  int id[AVACAP_MAX_FACERET];
  float landmark106[AVACAP_MAX_FACERET][212];
  float roll[AVACAP_MAX_FACERET];
} avacapArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct avacapRet {
  float alpha[AVACAP_MAX_FACERET][AVACAP_ID_LEN];
  float beta[AVACAP_MAX_FACERET][AVACAP_EXPR_LEN+1];
  float MV[AVACAP_MAX_FACERET][4][4];
  float MVP[AVACAP_MAX_FACERET][4][4];
  float rot3x3[AVACAP_MAX_FACERET][3][3];
  float trans[AVACAP_MAX_FACERET][3];
  float meshv[AVACAP_MAX_FACERET][AVACAP_VER_LEN][3];
  float mesh_tri_face[AVACAP_FACE_LEN][3];
  float proj[4][4];
  int id_len,exp_len,vertex_len,face_len;
  int face_count;
  int face_id[AVACAP_MAX_FACERET];
} avacapRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return avacap_CreateHandle
 */
AILAB_EXPORT
int avacap_CreateHandle(avacapHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return avacap_LoadModel
 */
AILAB_EXPORT
int avacap_LoadModel(avacapHandle handle,
                         avacapModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return avacap_LoadModelFromBuff
 */
AILAB_EXPORT
int avacap_LoadModelFromBuff(avacapHandle handle,
                                 avacapModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return avacap_SetParamF
 */
AILAB_EXPORT
int avacap_SetParamF(avacapHandle handle,
                         avacapParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT avacap_DO
 */
AILAB_EXPORT
int avacap_DO(avacapHandle handle,
                  avacapArgs* args,
                  avacapRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT avacap_ReleaseHandle
 */
AILAB_EXPORT
int avacap_ReleaseHandle(avacapHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT avacap_DbgPretty
 */
AILAB_EXPORT
int avacap_DbgPretty(avacapHandle handle);

  /**
   * @brief 为算法结果结构体申请空间, 如果空间是固定大小或者有上限的，可以无需传入参数
   *
   * @return AILAB_EXPORT avacap_MallocResultMemory
   */
  AILAB_EXPORT
  avacapRet* avacap_MallocResultMemory(avacapHandle handle);

  /**
   * @brief 释放算法输出结构体空间
   *
   * @param ret
   * @return AILAB_EXPORT avacap_FreeResultMemory
   */
  AILAB_EXPORT
  int avacap_FreeResultMemory(avacapRet* ret);
  
////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_AVACAPAPI_H_
