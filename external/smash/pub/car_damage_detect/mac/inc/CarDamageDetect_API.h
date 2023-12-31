#ifndef _SMASH_CARDAMAGEDETECTAPI_H_
#define _SMASH_CARDAMAGEDETECTAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* CarDamageDetectHandle;


/**
 * @brief 模型参数类型
 *
 */
typedef enum CarDamageDetectParamType {
  kCarMode = 1,
  kCarLandmarkMode = 2,
} CarDamageDetectParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum CarDamageDetectModelType {
  kCarDamageDetectModel1 = 1,
  kCarDamageDetectModel2 = 2,
  kCarDamageDetectModel3 = 3,
  kCarTrackingModel=4,
} CarDamageDetectModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct CarDamageDetectArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} CarDamageDetectArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */

typedef struct AILAB_EXPORT AIBrandInfoBase{
  AIPoint points_array[4];   //车牌关键点数组
  int brand_id;   //车牌id
  int brand_vi[10];
  int brand_vi_len;
}AIBrandInfoBase;

// CarLandmarksRecommendConfig 为算法推荐配置的算法参数，如CNN网络输入大小
typedef struct CarLandmarksRecommendConfig {
  int InputWidth;//200
  int InputHeight;//200
}CarLandmarksRecommendConfig;

#define MAX_CAR_NUM 16
#define AI_MAX_BRAND_NUM 10

typedef struct CarBoundingBox {
    int x0;
    int y0;
    int x1;
    int y1;
    int orient;  // 方向
}CarBoundingBox;

typedef struct CarDamageDetectRet {
  int car_count;  // 检到的车辆数
  int brand_count;  //检测到的车牌数量
  CarBoundingBox car_boxes[MAX_CAR_NUM];  // 车辆 bbox 数组
  AIBrandInfoBase base_infos[AI_MAX_BRAND_NUM];  //检测到的车牌信息，包括关键点、id
  double gray_score;
  double blur_score;
} CarDamageDetectRet;


typedef struct CarLandmarksRet {
  AIBrandInfoBase base_infos[AI_MAX_BRAND_NUM];  //检测到的车牌信息，包括关键点、id
  int brand_count;  //检测到的车牌数量
} CarLandmarksRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return CarDamageDetect_CreateHandle
 */
AILAB_EXPORT
int CarDamageDetect_CreateHandle(CarDamageDetectHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return CarDamageDetect_LoadModel
 */
AILAB_EXPORT
int CarDamageDetect_LoadModel(CarDamageDetectHandle handle,
                         CarDamageDetectModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return CarDamageDetect_LoadModelFromBuff
 */
AILAB_EXPORT
int CarDamageDetect_LoadModelFromBuff(CarDamageDetectHandle handle,
                                 CarDamageDetectModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return CarDamageDetect_SetParamF
 */
AILAB_EXPORT
int CarDamageDetect_SetParamF(CarDamageDetectHandle handle,
                         CarDamageDetectParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT CarDamageDetect_DO
 */
AILAB_EXPORT
int CarDamageDetect_DO(CarDamageDetectHandle handle,
                  CarDamageDetectArgs* args,
                  CarDamageDetectRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT CarDamageDetect_ReleaseHandle
 */
AILAB_EXPORT
int CarDamageDetect_ReleaseHandle(CarDamageDetectHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT CarDamageDetect_DbgPretty
 */
AILAB_EXPORT
int CarDamageDetect_DbgPretty(CarDamageDetectHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_CARDAMAGEDETECTAPI_H_
