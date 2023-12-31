#ifndef _SMASH_REFLECTIONLIVENESSAPI_H_
#define _SMASH_REFLECTIONLIVENESSAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

typedef void *ReflectionLivenessHandle;

/*5种stage: 用于外部调用者判断此时系统所处状态以及如何完成前段展示
 * WARMUP：外部不需完成任何额外显示
 * WAITFACE：外部需要展示定位框(圆形)，根据prompt code返回对应的提示文案
 * REFLECTION: 当第一次接收到REFLECTION状态时，开始进行光序列展示，
 * 展示定位框，根据promptcode返回提示文案；展示框周进度条
 * FINISH: 根绝detect code获取判断结果
 * PROCESS: 模型将阻塞约0.2s完成判断，外部可根据需要完成显示文案
 * */
//炫彩状态码
#define RL_WARMUP_STAGE 50
#define RL_WAITFACE_STAGE 51
#define RL_REFLECTION_STAGE 52
#define RL_FINISH_STAGE 53
#define RL_PROCESS_STAGE 54 //等待结果状态;

/*外部根据提示码显示文案：
 * NULL : 无异常，文案：请保持不动/不显示；
 * FACE_DIRECT : 未检测到人脸，文案：请将脸置于框内
 * RECT_GESTURE : 姿态不正，文案：请保持人脸端正
 * KEEP_ONE : 检测到多人，文案：请保持区域内仅有一人
 * NOT_OCCLUDE : 检测到遮挡，文案：请勿遮挡正脸
 * TO_BRIGHT : 光线不足，文案：请在光线充足的地方尝试
 * IN_WINDOW : 脸不在框内，文案：请将脸置于框内
 * NOT_MOVE : 图像模糊，文案: 请保持不动
 * LITTLE_CLOSE : 人脸过远，文案 : 请靠近一点
 * LITTLE_FAR : 人脸过进，文案 : 请远离一点，露出全脸
 * TIME_OUT : 超时，文案 : 解锁超时，请重试
 * */
//炫彩提示码
#define RL_PROMPT_NULL 100         //无提示
#define RL_PROMPT_FACE_DIRECT 101  //请出现在摄像头前
#define RL_PROMPT_RECT_GESTURE 102 //请保持人脸端正
#define RL_PROMPT_KEEP_ONE 103     //请保持区域内仅有一人
#define RL_PROMPT_NOT_OCCLUDE 104  //请勿遮挡正脸
#define RL_PROMPT_TO_BRIGHT 105    //请调整光照
#define RL_PROMPT_IN_WINDOW 106    //请将脸置于框内
#define RL_PROMPT_NOT_MOVE 107     //请保持不动(模糊)
#define RL_PROMPT_LITTLE_CLOSE 108 //请靠近一点
#define RL_PROMPT_TIME_OUT 109     //解锁超时
#define RL_PROMPT_LITTLE_FAR 110   //请远离一点

#define RL_PROMPT_AVOID_FLASH 111 //请避免强光照射

/*结果码返回模型判断结果；
 * REAL,通过炫彩活体
 * ATTACK,检测到假脸攻击，通过失败
 * INVALID,过程中中断，中断原因见PROMPT
 * ONGO,处理中，暂无活体结果
 * */
//炫彩结果
#define RL_RESULT_REAL 200 //活体成功
#define RL_RESULT_ATTACK                                                       \
    201 //活体失败(模型检测到攻击);
        //上层需弹窗询问是否重试，若重试则调取reset_machine
#define RL_RESULT_INVALID 202 //不符合人脸条件，中断; 上层需调取reset_state
#define RL_RESULT_ONGO 203 //流程中(结果码无效)
#define RL_RESULT_TIMEOUT                                                      \
    204 //活体失败，尝试次数过多(最大尝试时间);
        //上层需弹窗询问是否重试，若重试则调取reset_machine
#define RL_RESULT_ATTACK_ID                                                    \
    205 //活体失败(未通过ID比对);
        //上层需弹窗询问是否重试，若重试则调取reset_machine
#define RL_RESULT_OVER_MAXRETRY_TIMES                                          \
    206 //活体失败，尝试次数过多(超过最大尝试次数);
        //上层需弹窗询问是否重试，若重试则调取reset_machine

//其他参数
#define RL_AI_FACE_RL_MAX_REFLECTION_LIGHT_NUM 20
#define RL_MAX_FACE_NUM 10          //最大支持人脸数量
#define RL_FRAME_NUMBER_FOR_MODEL 4 //模型炫光及预测帧数
#define RL_SOFTMAX_LENGTH 3         //分类最大类别数
#define RL_LIGHT_SAVE_NUM 1 //单色单帧保存个数[当前评估下，固定为1]
#define RL_NOLIGHT_SAVE_NUM 2 //起始/终止帧个数[当前评估下，固定为2]

/**
 * @brief 模型参数类型
 */
typedef enum ReflectionLivenessParamType {
    REFLECTION_LIVENESS_RESET_MACHINE =
        0, //重置活体检测的状态,全自动机重启,需要外部计算重试次数
    REFLECTION_LIVENESS_RESET_STATE =
        1, //重置活体检测的状态,阶段重启(炫光中断，在超时限制内RETRY),不需要外部计算重试次数
    REFLECTION_LIVENESS_MASK_RADIUS_RATIO =
        2, //活体圆圈半径相对于整个屏幕宽度的占比，适配任意尺寸的图像输入，默认是0.375，float
    REFLECTION_LIVENESS_OFFSET_TO_CENTER_RATIO =
        3, //圆圈中心位置到顶部距离/整个屏幕宽度，适配任意尺寸的图像输入，默认是0.5，float
    REFLECTION_LIVENESS_MAX_RETRY_TIMES = 4, //单轮解锁最大重试次数, int
    REFLECTION_LIVENESS_MAX_TIME = 5,        //流程最长重试时间, float
    REFLECTION_LIVENESS_PER_FRAME_NUM = 6,   //单色光持续帧数, int
    REFLECTION_LIVENESS_REFLECION_THRED = 7, //炫彩模型阈值, float
    //	REFLECTION_LIVENESS_WARMUP_FRAMES = 8, //炫彩模型相机预热帧数，int
} ReflectionLivenessParamType;

/**
 * @brief 模型枚举，有些模块可能有多个模型
 */
typedef enum ReflectionLivenessModelType {
    LivenessConditionModel = 1,
    ReflectionLivenessModel = 2,
} ReflectionLivenessModelType;

/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct ReflectionLivenessArgs {
    ModuleBaseArgs base; //传入图像数据
} ReflectionLivenessArgs;

/**
 * @brief 炫彩活体的返回值
 *
 * @note current_stage:参考define部分注释
 * @note prompt_info:
 * @note detect_result_code:
 * @note real_prob: 真人置信度
 */
typedef struct ReflectionLivenessRet {
    int current_stage; //当前炫彩活体所处状态，包含warmup、waitface、reflection、finish
    int prompt_info;        //提示信息状态码
    int detect_result_code; //用于判断炫彩活体的结果
    float real_prob;        //真人置信度
    int nxt_light;          //下一帧上层所需显示颜色
    int frame_cnt;          //当前炫彩帧位置
    int total_frame;        //状态全部帧
} ReflectionLivenessRet;

/**
 * @brief 用于存储返回图像
 *
 * @note 最佳照片、活体照片回传中的数据存储
 */
typedef struct ReflectionLivenessImageData {
    unsigned char *image;
    int image_width;
    int image_height;
} ReflectionLivenessImageData;

/**
 * @brief 用于返回Log包
 * @note
 * 返回RL_FRAME_NUMBER_FOR_MODEL个炫彩帧(失败时各帧内容为nullptr/0/0)，以及logbuffer和log长度
 */
typedef struct ReflectionLivenessLog {
    ReflectionLivenessImageData frames[RL_FRAME_NUMBER_FOR_MODEL];
    char *logbuffer;
    int bufferlen;
};

/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ReflectionLiveness_CreateHandle
 */
AILAB_EXPORT
int ReflectionLiveness_CreateHandle(ReflectionLivenessHandle *out);

/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ReflectionLiveness_LoadModel
 */
AILAB_EXPORT
int ReflectionLiveness_LoadModel(ReflectionLivenessHandle handle,
                                 ReflectionLivenessModelType type,
                                 const char *model_path);

/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ReflectionLiveness_LoadModelFromBuff
 */
AILAB_EXPORT
int ReflectionLiveness_LoadModelFromBuff(ReflectionLivenessHandle handle,
                                         ReflectionLivenessModelType type,
                                         const char *mem_model, int model_size);

/**
 * @brief
 * 设置炫彩检测状态机的参数，对应可配置参数类型见ReflectionLivenessParamType
 *
 * @return
 */
AILAB_EXPORT
int ReflectionLiveness_SetParamF(ReflectionLivenessHandle handle,
                                 ReflectionLivenessParamType type, void *value);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ReflectionLiveness_DO
 */
AILAB_EXPORT
int ReflectionLiveness_DO(ReflectionLivenessHandle handle,
                          ReflectionLivenessArgs *args,
                          ReflectionLivenessRet *ret);

/**
 * @brief 获取活体照片和最佳照片
 *
 * @param handle
 * @param bestFrameEnv: 用于存储最佳照片大图
 * @param bestFrameFace: 用于存储最佳照片人脸图
 */
AILAB_EXPORT
int ReflectionLiveness_GetBestFrame(ReflectionLivenessHandle handle,
                                    ReflectionLivenessImageData *bestFrameEnv,
                                    ReflectionLivenessImageData *bestFrameFace);

/**
 * @brief 获取日志&数据
 *
 * @param handle
 * @param log: 用于获取模型的预测帧和log
 */
AILAB_EXPORT
int ReflectionLiveness_GetFramesLog(ReflectionLivenessHandle handle,
                                    ReflectionLivenessLog *log);

/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ReflectionLiveness_ReleaseHandle
 */
AILAB_EXPORT
int ReflectionLiveness_ReleaseHandle(ReflectionLivenessHandle handle);

/**
 * @brief 打印该模块的参数，用于调试
 *
 * @param handle
 * @return AILAB_EXPORT ReflectionLiveness_DbgPretty
 */
AILAB_EXPORT
int ReflectionLiveness_DbgPretty(ReflectionLivenessHandle handle);

/**
 * @brief 用于免流程测试，支持N图测试，当N为1是为单帧测试
 *
 * @param args：ReflectionLivenessArgs的指针数组
 * @return
 */
AILAB_EXPORT
int ReflectionLiveness_Test(ReflectionLivenessHandle handle,
                            ReflectionLivenessArgs **args, int num_arg,
                            ReflectionLivenessRet *ret,
                            unsigned long long **conditions);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
///////////////////////////////////////////

#ifdef __cplusplus
}
#endif // __cplusplus

// clang-format on
#endif // _SMASH_REFLECTIONLIVENESSAPI_H_
