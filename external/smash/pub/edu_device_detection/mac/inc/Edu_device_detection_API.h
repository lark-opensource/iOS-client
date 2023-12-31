#ifndef _SMASH_Edu_device_detectionAPI_H_
#define _SMASH_Edu_device_detectionAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

#define NUM_Edu_device_detection_DEVICES 30

  // clang-format off
typedef void* Edu_device_detectionHandle;




/**
 * @brief 模型参数类型，教具套ID（categoryID）
 *
 */
typedef enum Edu_device_detectionParamType {
  Edu_device_detection_Tangram = 1,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）七巧板的结果
  Edu_device_detection_Number = 2,   //传入值0或者1，默认为0。0(1)分别代表不输出（输出）数字的结果
  Edu_device_detection_ColorPlate = 3,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）颜色板的结果
  Edu_device_detection_GeoShape = 4,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）几何形状的结果
  Edu_device_detection_Dice = 5,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）点板的结果
  Edu_device_detection_Arrow = 6,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）运行键（箭头/播放）的结果
  Edu_device_detection_IP = 7,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）IP形象板的结果
  Edu_device_detection_OP = 8,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）数学运算符的结果
  Edu_device_detection_Axis = 9,  //传入值0或者1，默认为0。0(1)分别代表不输出（输出）数轴的结果
  Edu_device_detection_3D_Device = 10,  //已划入运行类/箭头类，传入值0或者1，默认为0。0(1)分别代表不输出（输出）播放按钮的结果
  Edu_device_detectionStableFrameNum = 11,          //稳定帧区间值,目前默认值是10
  Edu_device_detectionDetEnvSwitch = 12,            //检测环境开关，0表示不检测，1表示检测
  Edu_device_detectionDetEnvNum = 13,               //检测环境区间值，默认是30帧
  EDU_SWITCH_CARD_PROGRAM_ON = 14,                  // 是否开启编程卡牌处理逻辑
  EDU_SWITCH_CARD_NUMBER_ON = 15,                  // 是否开启数字卡牌处理逻辑
} Edu_device_detectionParamType;

/**
 * @brief 模型枚举，有些模块可能有多个模型
  *目前包含颜色定位模型，教具分类模型，轮廓定位模型；未来会增加桌垫识别模型、无效帧过滤模型等
 */
typedef enum Edu_device_detectionModelType {
  kEdu_device_detectionModel1 = 1,          ///< TODO: 默认保留扩展模型标志变量
  Edu_device_detectionModel_color = 2,  //
  Edu_device_detectionDevice_cls = 3,  //
  Edu_device_detectionModel_cnt = 4,   //number游戏模型
} Edu_device_detectionModelType;

/**
 * @brief 环境枚举，每个枚举值代表不同的环境
 * @note 改为bitset的方式返回多类环境检测结果，通过按位与（&）判断环境检测结果类型
 */
typedef enum Edu_device_detectionEnvironmentType {
  Edu_device_detection_OverExposure = 1,    //过曝（过亮）
  Edu_device_detection_UnderExposure = (1 << 1),   //欠曝（过暗）
  Edu_device_detection_NoMat = (1 << 2),           //无桌垫
  Edu_device_detection_Occlusion = (1 << 3),       //棱镜遮挡
  Edu_device_detection_AbnormalRatio = (1 << 4),       //比例异常
} Edu_device_detectionEnvironmentType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct Edu_device_detectionArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} Edu_device_detectionArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */


typedef struct DeviceCategoryItem {
    float x;    //教具x坐标
    float y;    //教具y坐标
    int h;
    int w;
    float orientation;   // 默认值181，0 right;  180/-180 left;  90 up; -90 down;
    bool satisfied;      //教具是否出现
    int deviceID;        //教具ID
    int direction;       // 暂未使用，本打算留给七巧板等其他特殊方向要求的教具
    float cls_prob;      // 分类概率，业务目前未使用
} DeviceCategoryItem;


typedef struct DeviceRet {
    DeviceCategoryItem items[NUM_Edu_device_detection_DEVICES];
    bool is_stable;      //1.2.2新增字段，判断教具是否稳定
    int environment;      //1.2.2新增字段 环境光线判断，是否遮挡等，默认值为-1
} DeviceRet;


/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return Edu_device_detection_CreateHandle
 */
AILAB_EXPORT
int Edu_device_detection_CreateHandle(Edu_device_detectionHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return Edu_device_detection_LoadModel
 */
AILAB_EXPORT
int Edu_device_detection_LoadModel(Edu_device_detectionHandle handle,
                         Edu_device_detectionModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return Edu_device_detection_LoadModelFromBuff
 */
AILAB_EXPORT
int Edu_device_detection_LoadModelFromBuff(Edu_device_detectionHandle handle,
                                 Edu_device_detectionModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return Edu_device_detection_SetParamF
 */
AILAB_EXPORT
int Edu_device_detection_SetParamF(Edu_device_detectionHandle handle,
                         Edu_device_detectionParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT Edu_device_detection_DO
 */
AILAB_EXPORT
int Edu_device_detection_DO(Edu_device_detectionHandle handle,
                  Edu_device_detectionArgs* args,
                  DeviceRet* ret);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT Edu_device_detection_ReleaseHandle
 */
AILAB_EXPORT
int Edu_device_detection_ReleaseHandle(Edu_device_detectionHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT Edu_device_detection_DbgPretty
 */
AILAB_EXPORT
int Edu_device_detection_DbgPretty(Edu_device_detectionHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief 版本号
 *
 * @return AILAB_EXPORT 版本号（x.x.x）
 */
AILAB_EXPORT
const char* Edu_device_detection_GetVersion();

// only for debug
struct Edu_device_detectionRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
};

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_Edu_device_detectionAPI_H_
