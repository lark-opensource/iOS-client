//
// Created by 王旭 on 2018/8/24.
//

#ifndef MODULES_ACTIONLIVENESS_API_H
#define MODULES_ACTIONLIVENESS_API_H

#include "tt_common.h"
#include "smash_module_tpl.h"

#if defined __cplusplus
extern "C" {
#endif
	
	typedef void *ActionLivenessHandle;

	typedef struct AILAB_EXPORT ActionLivenessArgs {
		ModuleBaseArgs base;
	}ActionLivenessArgs;

	typedef enum ActionLivenessModelType {
		kActionLivenessModel1 = 800,          ///< TODO: 根据实际情况更改
		kActionLivenessActionType = 801,
	}ActionLivenessModelType;

	// 用于获取活体检测过程中的最佳照片
	typedef struct AILAB_EXPORT ActionLivenessBestFrame{
		unsigned char *image;   //用于存储最佳图像，可以是包含背景的图像或者是人脸图像
		int image_width;     //获取最佳照片的宽度
		int image_height;    //获取最佳照片的宽度
        bool mask_flag;
	}ActionLivenessBestFrame;

	// 用于活体失败时抓取关键日志
	typedef struct AILAB_EXPORT ActionLivenessResultLog{
		ActionLivenessBestFrame liveness_image; // 失败时候的图片
		ActionLivenessBestFrame face_verify_image[2]; // 0: 激活活体的图 1：预留，目前为空
		char *logbuffer; // 目前动作成功会返回"succeed",失败会返回"fail"，预留后续补充更多
		int bufferlen;
	}ActionLivenessResultLog;

	/**
	 * @brief 用于返回Log包
	 */
	typedef struct AILAB_EXPORT ActionLivenessLog{
			char *logbuffer;
			int bufferlen;
	}ActionLivenessLog;

	/**
	 * @brief 用于返回人脸质量的分析结果
	 */
	typedef struct AILAB_EXPORT ActionLivenessFrameQuality{
			/* @face_quality
			 //人脸质量分析结果
			 //   bit	解释(全部为1表示通过，某一位为0需要提示对应信息)
			 // 	0 	未检测到人脸
			 // 	1		检测到多张脸
			 //   2		请靠近点
			 // 	3 	不要遮挡
			 // 	4 	将脸置于框内
			 // 	5 	光线不足
			 //   6   避免强光
			 //   7   调整至合理姿态
			 */
			unsigned int face_quality;
        

			/* @recommend_prompt
			 //推荐提示文案
			 103 = "请勿遮挡并直面镜头",
			 104 = "请靠近点",
			 106 = "请保持端正",
			 107 = "质量合格",
			 108 = "请确认只有一张人脸",
			 109 = "请保持睁眼",
			 110 = "请露出完整人脸",
			 111 ="请保持人脸在框内",
			 112 = "请在明亮环境下完成操作",
			 113 = "避免强光",
			 114 = "请不要张嘴",
			 116 = "请保持姿态端正"};
			 */
			int recommend_prompt;
	}ActionLivenessFrameQuality;
	// 用于保存活体检测返回值的结构体参数
	/*
	stage_machine_stage一共有六种，用于外部调用者判断此时系统所处的状态和是否需要给出提示信息！其中：
	STATE_MACHINE_WARMTIME是摄像头的启动时间，这个阶段不需要图像以外的任何显示和反馈；
	STATE_MACHINE_WAITTIME需要显示第一种提示信息，需要提示用户满足合理的条件(如姿态、距离、光线等)，进入活体；
	STATE_MACHINE_PENDTIME是动作切换时间，不需要有任何图像以外的显示和反馈；
	STATE_MACHINE_ONGOTIME是动作进行时间，此时需要显示第二种提示信息和第一种提示信息，就是既需要提示动作要求也需要提示额外的反馈信息，保证活体的顺利进行。唯一需要注意的是，prompt115(静默失效)只用于debug模式，正常使用的时候这一条不能提示。
	STATE_MACHINE_OVERTIME是结束状态，表示活体已经完成。
	STATE_MACHINE_PREDTIME是识别和活体模型的推理时间。
	state_machine_stage:{
	STATE_MACHINE_WARMTIME -1  //无显示
	STATE_MACHINE_WAITTIME 0  //显示第一种提示信息
	STATE_MACHINE_PENDTIME 1   //无显示
	STATE_MACHINE_ONGOTIME 2  //显示第二种提示信息(动作类型) + 显示剩余时间(进度条) + 显示第一种提示信息
	STATE_MACHINE_OVERTIME 3  //显示成功或者失败
	STATE_MACHINE_PREDTIME 4  //识别or活体模型工作时间，无显示
	}
	*/
	 
	/*
	 category可能的返回值一共有五种，用来提示用户做哪些动作，-1不代表任何动作。
	 category: {-1 = "空动作", 0 = "眨眼", 1 = "张嘴", 2 = "点头", 3 = "摇头"}   //当前帧对应的动作信息(第二种提示信息)
	*/

	 /*
	 category_status主要用于埋点。任何动作通过或者失败了，都会有且仅有一次51或者52的状态返回。
	 category_status:{ 54 = 开始活体过程(用于埋点)，53 = 无效状态(动作过程尚未有结果), 51 = 当前动作成功, 52 = 当前动作失败 } //当前帧对应的动作状态
	 */
	
	 /*
	 timeleft用于返回当前动作的剩余时间，只有在STATE_MACHINE_ONGOTIME阶段有使用意义。
	 timeleft: 用于提示剩余时间(第二种提示信息)
	 */

	 /*
	 prompt_info是客户端需要给到用户的提示信息，在STATE_MACHINE_WAITTIME和STATE_MACHINE_ONGOTIME都会用到，其中115 = "本帧静默无效"(仅用于debug模式)。
	 prompt_info: {101 = "检测失败", 102 = "检测成功", 103 = "请勿遮挡并直面镜头",
	 104 = "请靠近点", 105 = "请不要过快"(废弃), 106 = "请保持端正", 107 = "",
	 108 = "请确认只有一张人脸", 109 = "请保持睁眼", 110 = "请露出完整人脸",
	 111 ="请保持人脸在框内", 112 = "请在明亮环境下完成操作", 113 = "避免强光", 114 = "请不要张嘴",
	 115 = "本帧静默无效"(仅用于debug模式), 116 = "请保持姿态端正"};  //动作提示信息(第一种提示信息)
	 
	 detect_result_code:{ 0 = "检测尚未完成", 1 = "检测成功", 2 = "超时未检测到第一张有效人脸",
	 3 = "单个动作超时", 6 = "做错动作，可能是视频攻击", 7 = "静默活体检测失败", 8 = "过程中人脸不一致"， 9 = "过程中图片质量不合格"}
	 */
	typedef struct AILAB_EXPORT ActionLivenessRet {
		int category;    // 做的动作类型，二级提示信息
		int category_status;   //当前帧对应动作的结果信息，用于埋点
		int timeleft;    // 当前动作的剩余时间
		int state_machine_stage;   //状态机当前状态
		int prompt_info;      // 状态信息
		int detect_result_code;   //用于判断活体检测的结果，提取具体的错误信息等
        float key_stable; // 判断关键点稳定性
        float blink_prob; // 判断眨眼发生的可能性
        float risk_prob; // 是否有攻击风险
        int action_number;
	} ActionLivenessOutput;
	
	//用于客户端定义需要下发的检测动作
	typedef enum ActionLivenessActionCmd{
		k_ActionLivenessBlink = 0,  //眨眼
		k_ActionLivenessOpenMouth = 1,  //张嘴
		k_ActionLivenessNod = 2,   //点头
		k_ActionLivenessShake = 3,  //摇头
		k_ActionLivenessHeadUpOrDown = 4,   //抬头或低头
		k_ActionLivenessHeadLeftOrRight = 5,  //左偏或右偏
	} ActionLivenessActionCmd;
	
	
	//用于设置活体检测各种模式的配置参数
	typedef enum ActionLivenessParamType {
		ACTION_LIVENESS_RESET = 0,    						 		//重置活体检测的状态，int
		ACTION_LIVENESS_TIME_PER_ACTION = 1,    	 		//每个动作的允许时间，float
		ACTION_LIVENESS_ACTION_LIST = 2,    	  	 		//需要完成的动作序列，int, 00001111  0 = "眨眼", 1 = "张嘴", 2 = "点头", 3 = 																			   		"摇头"，当数值小于255时只能下发动作类型，有序下发见下面的用法解释。
		ACTION_LIVENESS_RE_ID_TIME_LIMIT = 5,   	 		//重新定位人脸的允许时间，推荐0.3-0.5, float
		ACTION_LIVENESS_RANDOM_ORDER = 7,   	 		 		//随机顺序模式，推荐1，int
		ACTION_LIVENESS_DETECT_ACTION_NUMBER = 9,  		//需要检测的动作数量, int
		ACTION_LIVENESS_TIME_BTW_ACTION = 11,  		 	  //动作切换的时间间隔, 推荐1.0-2.0,  float
		ACTION_LIVENESS_STILL_LIVENESS_THRESH = 13, 	//如果配置静默活体的话，支持设置阈值, float
		ACTION_LIVENESS_FACE_SIMILARITY_THRESH = 14,	//如果配置了人脸识别的话，支持设置阈值，float
		ACTION_LIVENESS_MASK_RADIUS_RATIO = 15, 			//活体圆圈半径相对于整个屏幕宽度的占比，适配任意尺寸的图像输入，默认是0.375，float
		ACTION_LIVENESS_OFFSET_TO_CENTER_RATIO = 16, 	//圆圈中心位置到顶部距离/整个屏幕高度，适配任意尺寸的图像输入，默认是0.37，float
		ACTION_LIVENESS_TIME_FOR_WAIT_FACE = 17, 			//允许的最大等待人脸时间
		ACTION_LIVENESS_FACE_OCCUPY_RATIO = 18, 			//用于控制人脸占比的参数，影响检测距离
		ACTION_LIVENESS_DEBUG_MODE=20,  							//调试模式
		ACTION_LIVENESS_CONTINUOUS_MODE = 21, 				//连续且严格的动作检测，默认false，int
		ACTION_LIVENESS_MAX_LOSE_NUMBER = 22, 				//人脸最大丢失次数，安全场景下全程人脸不允许丢失。默认为正无穷。
		ACTION_LIVENESS_WRONG_ACTION_MODE = 23,				//是否需要做错误动作检测，默认关闭，int，可以参考文档: 																						bytedance.feishu.cn/docs/doccnfJuxSVpqRv3VqBzTsYUgHd
		ACTION_LIVENESS_WRONG_ACTION_INVALID_TIME = 24,
        ACTION_LIVENESS_ROTATE_FLAG = 25,
        ACTION_LIVENESS_SAFE_MORE = 26,
        ACTION_LIVENESS_MASK_MODE = 27,
        ACTION_LIVENESS_CAPTURE_MODE = 28,
        ACTION_LIVENESS_QUALITY_THRESH = 29,
        ACTION_LIVENESS_QUALITY_CACHE = 30,
        ACTION_LIVENESS_STABLE_THRESH = 31,
        ACTION_LIVENESS_FACE_ANGLE = 38
																									//当第N个（N >= 2）新动作提示开始后，在Invalid_time内，不会触发错误动作检测，但是对应指令的动作仍然会被检测。
																									//时间设置过短，容易上个动作还没结束，这里就检测到错误动作了；时间设置过长，会降低黑产随机视频攻击的门槛。
																									//float型，默认1.0，推荐0.1 - 2.0。
		
	}ActionLivenessParamType;	
	
	//创建handler
	AILAB_EXPORT
	int ActionLiveness_CreateHandle(ActionLivenessHandle *handle);
	
	//设置活体检测状态机的参数，对应可配置参数类型见LivenessParamType
	AILAB_EXPORT
	int ActionLiveness_SetParamS(ActionLivenessHandle handle, ActionLivenessParamType type, void* value);
	
	//设置活体检测系统需要加载的模型文件，model_path为模型路径
	AILAB_EXPORT
	int ActionLiveness_LoadModel(ActionLivenessHandle handle, ActionLivenessModelType type, const char *model_path);
	
	
	// 保留接口
	AILAB_EXPORT
	int ActionLiveness_LoadModelFromBuf(ActionLivenessHandle handle,
																			ActionLivenessModelType type,
																			const char *mem_model,
																			int model_size);
	
	//输入一张图，活体检测的状态机进行预测
	AILAB_EXPORT
	int ActionLiveness_Predict(ActionLivenessHandle handle, ActionLivenessArgs *args, ActionLivenessRet *ret);

//	AILAB_EXPORT
//	int ActionLiveness_Predict(ActionLivenessHandle handle, ActionLivenessArgs *args, ActionLivenessRet *ret, int val);
	
	//获取检测过程的最佳照片，用于后续人证比对
	AILAB_EXPORT
	int ActionLiveness_BestFrame(ActionLivenessHandle handle,
												 ActionLivenessBestFrame *bestFrameEnv,      //包含背景的最佳图像，现优化输出文件的尺寸，Env图像的尺寸为360*480*4
												 ActionLivenessBestFrame *bestFrameFace);    //仅包含人脸的最佳图像，现优化输出文件的尺寸，Face图像的尺寸为250*250*4。

	/**
	 * @brief 获取日志&数据
	 */
	AILAB_EXPORT
	int ActionLiveness_GetFramesLog(ActionLivenessHandle handle, ActionLivenessResultLog *log);

	/**
	 * @brief 获取静默活体的分析结果
	 */
	AILAB_EXPORT
	int ActionLiveness_GetStillLivenessResults(ActionLivenessHandle handle, float* scores, int& len);

		
	/**
	 * @brief 人脸质量分析，用于抓拍等场景
	 * @ret 人脸质量分析结果
	 */

	AILAB_EXPORT
	int ActionLiveness_PredQuality(ActionLivenessHandle handle, ActionLivenessArgs *args, ActionLivenessFrameQuality *ret);
	
	//释放资源
	AILAB_EXPORT
	void ActionLiveness_Release(ActionLivenessHandle handle);
	
    typedef struct AILAB_EXPORT ActionLivenessModelName {
        // 模型名， e.g tt_liveness_v10.0.model
        char namebuffer[30];
        // sdk版本号, e.g 3.2
        char version_sdk[10];
    }ActionLivenessModelName;

    AILAB_EXPORT
    int ActionLiveness_GetModelVersion(ActionLivenessModelName *ret);
	
#if defined __cplusplus
}
#endif

#endif //MODULES_LIVENESS_API_H

