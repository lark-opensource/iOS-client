#ifndef _SMASH_TANGRAMRECOGNITIONAPI_H_
#define _SMASH_TANGRAMRECOGNITIONAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

  // clang-format off
typedef void* TangramRecognitionHandle;

#define NUM_TANGRAM_VERTEX_NUMBER 32
#define NUM_TANGRAM_NUMBER 8
#define NUM_TANGRAM_ANWSER_NUM 512
/**
 * @brief 模型参数类型
 *
 */
typedef enum TangramRecognitionParamType {
  kTangramRecognitionPrintLog =9,             //是否打印日志
  kTangramRecognitionEdgeMode = 10,        ///< TODO: 根据实际情况修改
  TangramRecognitionStableFrameNum = 11,          //稳定帧区间值,目前默认值是10
  TangramRecognitionDetEnvSwitch = 12,            //检测环境开关，0表示不检测，1表示检测
  TangramRecognitionDetEnvNum = 13,               //检测环境区间值，默认是30帧
  TangramDistThres = 14,               //设置七巧板距离阈值，区间范围（0，1），默认是0.45
  TangramAngleThres = 15,               //设置七巧板角度阈值，区间范围（0，90），默认是35度
  TangramPairAngleThres = 16,               //设置七巧板两两相对角度阈值，区间范围（0，90），默认是30度
  // 位置提示相关参数
  TangramLocTopMargin = 17,                 // 设置位置提醒上边缘阈值，默认45
  TangramLocBottomMargin = 18,              // 设置位置提醒下边缘阈值，默认120
  TangramLocRightMargin = 19,               // 设置位置提醒左边缘阈值，默认-30 （负数表示允许超出边界）
  TangramLocLeftMargin = 20,                // 设置位置提醒右边缘阈值，默认-30 （负数表示允许超出边界）
  TangramLocMaxThres = 21,                  // 设置位置提醒时候，根据答案可以猜测的最远距离，默认130
} TangramRecognitionParamType;

typedef enum Direction {
  NOMOVE=0,
  TOP=1,
  BOTTOM=2,
  LEFT=3,
  RIGHT=4,
  TOP_RIGHT=5,
  BOTTOM_RIGHT=6,
  BOTTOM_LEFT=7,
  TOP_LEFT=8
} Direction;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum TangramRecognitionModelType {
  kTangramRecognitionModel1 = 7,          ///< TODO: 根据实际情况更改
} TangramRecognitionModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct TangramRecognitionArgs {
  ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
  // 此处可以添加额外的算法参数
} TangramRecognitionArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 教具ID顺序:  ['0: large_blue_tri', '1: large_red_tri', '2: mid_yellow_tri', '3: small_pink_tri', '4: small_purple_tri', '5: square', '6: parallelgram1', '7: parallelgram2']
 */
//顶点数据结构
typedef struct VertexCoordinateItem {
    float x;    //教具x坐标
    float y;    //教具y坐标
} VertexCoordinateItem;

//每个板子(tans)的属性信息
typedef struct TangramItem {
    float orientation;   // 0-360度
    int place;           //bit-map值确定，0，1，2三位分别表示是否放置教具、是否放对教具（初定用于平行四边形），是否放对且位置和角度都对
    int deviceID;        //教具ID
    float cls_prob;      // 分类概率，业务目前未使用
    int tangram_num;     // 板子的数目，用于多个相同板子出现时的移除提示
} TangramItem;

/**
* @brief SDK返回识别的当前拼图的每个七巧板的几何信息以及当前拼图匹配的答案ID
*                  也会返回环境检测的信息以及稳定态字段
* @TangramRecognitionRet  每个拼图答案最多包含8个七巧板，每个七巧板最多4个顶点
 */

typedef struct TangramRecognitionRet {
    VertexCoordinateItem coord_items[NUM_TANGRAM_VERTEX_NUMBER]; //4*8个顶点
    TangramItem tans_items[NUM_TANGRAM_NUMBER];            //8个tans
    bool is_stable;      //1.2.2新增字段，判断教具是否稳定
    int environment;      //1.2.2新增字段 环境光线判断，是否遮挡等，默认值为-1
    int direction;        //判断当前用户拼图是否需要移动，默认0表示不需要移动。
    int answer_id;        //锁定的答案ID, 如中间拼图有多个答案，返回匹配答案中任一个。
} TangramRecognitionRet;

typedef enum TangramRecognitionEnvironmentType {
  TangramRecognition_OverExposure = 1,    //过曝（过亮）
  TangramRecognition_UnderExposure = (1 << 1),   //欠曝（过暗）
  TangramRecognition_NoMat = (1 << 2),           //无桌垫
  TangramRecognition_Occlusion = (1 << 3),       //棱镜遮挡
  TangramRecognition_AbnormalRatio = (1 << 4),       //比例异常
} TangramRecognitionEnvironmentType;

typedef enum TangramRecognitionPlaceType {
  TangramRecognition_IsPlace = 1,    //是否放置教具
  TangramRecognition_IsFit = (1 << 1),   //是否放对位置教具（is_fit,初定用于平行四边形,正反面未必对）
  TangramRecognition_Satisfied = (1 << 2),           //satisfied
} TangramRecognitionPlaceType;


/**
* @brief 游戏传递给sdk的拼图答案
*
* @TangramAnwser  每个拼图答案最多包含8个七巧板，每个七巧板最多4个顶点
* @TangramAnwserList 每个拼图最多有512个答案
*/

//float TangramAnswerList[NUM_TANGRAM_ANWSER_NUM*64];
/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return TangramRecognition_CreateHandle
 */
AILAB_EXPORT
int TangramRecognition_CreateHandle(TangramRecognitionHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return TangramRecognition_LoadModel
 */
AILAB_EXPORT
int TangramRecognition_LoadModel(TangramRecognitionHandle handle,
                         TangramRecognitionModelType type,
                         const char* model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return TangramRecognition_LoadModelFromBuff
 */
AILAB_EXPORT
int TangramRecognition_LoadModelFromBuff(TangramRecognitionHandle handle,
                                 TangramRecognitionModelType type,
                                 const char* mem_model,
                                 int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 *
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return TangramRecognition_SetParamF
 */
AILAB_EXPORT
int TangramRecognition_SetParamF(TangramRecognitionHandle handle,
                         TangramRecognitionParamType type,
                         float value);



/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT TangramRecognition_DO
 */
AILAB_EXPORT
int TangramRecognition_DO(TangramRecognitionHandle handle,
                  TangramRecognitionArgs* args,
                  TangramRecognitionRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT TangramRecognition_ReleaseHandle
 */
AILAB_EXPORT
int TangramRecognition_ReleaseHandle(TangramRecognitionHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT TangramRecognition_DbgPretty
 */
AILAB_EXPORT
int TangramRecognition_DbgPretty(TangramRecognitionHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief 版本号
 *
 * @return AILAB_EXPORT 版本号（x.x.x）
 */
AILAB_EXPORT
const char* TangramRecognition_GetVersion();


/**
 * @brief 下发答案数据给SDK
 * @param element_num: answer_list的长度
 * @return send anwserlist
 */
AILAB_EXPORT
int TangramRecognition_SendAnswerList(TangramRecognitionHandle handle, float* answer_list, int element_num);


// only for debug
typedef struct TangramRecognitionDebugRet {
  // 下面只做举例，不同的算法需要单独设置
  unsigned char* alpha;        ///< alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  unsigned char* tangram_seg; // tangram mask 0 - 7
  int width;                   ///< 指定alpha的宽度
  int height;                  ///< 指定alpha的高度
} TangramRecognitionDebugRet;

AILAB_EXPORT
int TangramRecognition_DO_Debug(TangramRecognitionHandle handle,
                  TangramRecognitionArgs* args,
                  TangramRecognitionDebugRet* ret);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_TANGRAMRECOGNITIONAPI_H_
