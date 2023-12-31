#ifndef _SMASH_FaceNewLandmarkAPI_H_
#define _SMASH_FaceNewLandmarkAPI_H_

#include "FaceSDK_API.h"
//#include "smash_module_tpl.h"
//#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus
#define BASE_ALIGN_FACE_POINT_NUM 106 // crop人脸区域所需要的参考点，FaceSDK预测得到的人脸106关键点
#define FACE_OUTLINE_NUM_CUR 88  // 44理想点+44实际点  目前模型只预测88点，之后升级会新增4个点，增在最后4位
#define FACE_OUTLINE_NUM_FINAL 92  //完善的92新轮廓点 前88是 44理想点+44实际点  +2（14/15中点）+2 （30/29中点）（预留出接口，理想点和实际点各增2 ）
#define AI_MAX_FACE_NUM_FACE_NEW_LANDMARK AI_MAX_FACE_NUM // 支持的最大人脸数  
#define FACE_OUTLINE_INDEX_BEGIN 0  //人脸外轮廓在预测结果 FaceNewLandmark_Output 开始的点位
    
    // handle
    typedef void* FaceNewLandmark_Handle;
    
    // 设置相关预测参数： 目前包括m_escale_outline，平滑参数
    typedef struct FaceNewLandmark_Config
    {
        int m_escale_outline;
    } FaceNewLandmark_Config;
    
    // 模块的输入之一：FaceSDK预测得到的人脸基本信息
    typedef struct FaceBaseInfo_St
    {
        int face_id;  //face_id 表示当前人脸face_id, 同一张图像中，不同人脸，face_id不一样
        AIPoint points[BASE_ALIGN_FACE_POINT_NUM]; //points表示当前face_id人脸，对应的FaceSDK预测得到的人脸106关键点，用来crop人脸区域
    } FaceBaseInfo;
    
    // 模块输入
    typedef struct FaceNewLandmark_Input_St
    {
        unsigned char* image;   // 图像
        int image_width;
        int image_height;
        int image_stride;
        PixelFormatType pixel_format; // 图像格式 kPixelFormat_BGRA8888 或者 kPixelFormat_RGBA8888
        ScreenOrient orient;          // 图像旋转角度
        FaceBaseInfo* faceBase_info;  // FaceSDK预测得到的人脸基本信息，用来crop人脸区域
        int face_count;               // 当前图像包含的人脸个数
    } FaceNewLandmark_Input;
    
    
    // 模块输出
    
    /*
    单独一个人的所有点位预测结果
    外部不可以直接调用
    通过 FaceNewLandmark_Output.all_face_result[n]来调用第n个人的预测结果
    */
    typedef struct FaceNewLandmark_Single_Result_St
    {
        int face_id;
        AIPoint* FaceNewLandmark_all_pts; // 人脸新增的所有点位，其中1～92点位代表新轮廓点92个点（包括44理想点/44实际点/4预留接口），93-？鼻子点、 脖子点, 因为不确定多少点，所以使用指针类型
    } FaceNewLandmark_Single_Result;
    
    /*
    当前图像所有人的所有点预测结果
    最终输出到外部， 外部可以直接调用
    */
    typedef struct FaceNewLandmark_Output_St
    {
        FaceNewLandmark_Single_Result all_face_result[AI_MAX_FACE_NUM_FACE_NEW_LANDMARK];  //所有人的所有点预测结果
        int face_count;   // 人脸数
    } FaceNewLandmark_Output;
    
    /*
    单独一个人的轮廓点预测结果
    不可单独调用
    通过 FaceNewLandmark_GetOutlineInfo 获取所有人的 FaceOutline_Output， 然后 FaceOutline_Output.all_face_outline_result[n] 对应第n个人的轮廓点预测结果
    */
    typedef struct Face_outline_Single_Result_St
    {
        int face_id;  //当前人的face_id
        AIPoint face_outline_pts[FACE_OUTLINE_NUM_FINAL]; // 与当前face_id对应的人脸新轮廓点92个点： 包括44理想点/44实际点/4预留接口
    } Face_outline_Single_Result;
    
    /*
    当前图像所有人的轮廓点预测结果
    不可单独调用
    通过FaceNewLandmark_GetOutlineInfo来获取
     */
    typedef struct FaceOutline_Output_St
    {
        Face_outline_Single_Result all_face_outline_result[AI_MAX_FACE_NUM_FACE_NEW_LANDMARK];
        int face_count;
    } FaceOutline_Output;
    
    /**
    “轮廓点” 是 “所有点位”中的一部分，想要单独获取 “轮廓点”，需要通过FaceNewLandmark_GetOutlineInfo 这个函数
     输入：@FaceNewLandmark_info 预测得到的所有点位   @handle 当前模块对应的handle
     输出：@Face_outline_Result 预测得到轮廓点，包含在所有点位FaceNewLandmark_info中
     */
    int FaceNewLandmark_GetOutlineInfo(FaceNewLandmark_Output* FaceNewLandmark_info, FaceNewLandmark_Handle handle, FaceOutline_Output* Face_outline_Result);
    
    //  模型参数类型
    typedef enum FaceNewLandmarkParamType
    {
        kFaceNewLandmarkEdgeMode = 1,
    } FaceNewLandmarkParamType;
    
    // @brief 相关的模型选择，暂时没有用到 有些模块可能有多个模型
    
    typedef enum FaceNewLandmarkModelType
    {
        kFaceNewLandmarkModel1 = 1, ///< TODO: 根据实际情况更改
    } FaceNewLandmarkModelType;
    
    // 申请预测结果内存
    AILAB_EXPORT
    FaceNewLandmark_Output* FaceNewLandmark_MallocResultMemory(FaceNewLandmark_Handle handle);
    
    // 退出释放结果内存
    AILAB_EXPORT
    int FaceNewLandmark_FreeResultMemory(FaceNewLandmark_Output* p_FaceNewLandmark_info);
    
    // 申请内存: 外轮廓点
    AILAB_EXPORT
    FaceOutline_Output* FaceNewLandmark_MallocResultMemoryFaceoutline(FaceNewLandmark_Handle handle);
    
    // 退出释放外轮廓点结果内存
    AILAB_EXPORT
    int FaceNewLandmark_FreeResultMemoryFaceoutline(FaceOutline_Output* p_face_outline_result);
    
    // 创建句柄
    
    AILAB_EXPORT
    int FaceNewLandmark_CreateHandle(FaceNewLandmark_Handle* out);
    
    // 从文件路径加载模型
    AILAB_EXPORT
    int FaceNewLandmark_LoadModel(FaceNewLandmark_Handle handle, FaceNewLandmarkModelType type, const char* model_path);
    
    // 加载模型（从内存中加载，Android 推荐使用该接口）
    AILAB_EXPORT
    int FaceNewLandmark_LoadModelFromBuff(FaceNewLandmark_Handle handle,
                                     FaceNewLandmarkModelType type,
                                     const char* mem_model,
                                     int model_size);
    
    /**
     * @param handle 句柄
     * @param type 设置参数的类型
     * @param value 设置参数的值
     * @return FaceNewLandmark_SetParamF
     */
    AILAB_EXPORT
    int FaceNewLandmark_SetParamF(FaceNewLandmark_Handle handle, FaceNewLandmarkParamType type, float value);
    
    // 预测模型
    AILAB_EXPORT
    int FaceNewLandmark_DO(FaceNewLandmark_Handle handle,
                      FaceNewLandmark_Input* input_info,
                      FaceNewLandmark_Output* p_FaceNewLandmark_info);
    
    // 销毁句柄，释放资源
    AILAB_EXPORT
    int FaceNewLandmark_ReleaseHandle(FaceNewLandmark_Handle handle);
    
    
#ifdef __cplusplus
}
#endif // __cplusplus

#endif // _SMASH_FaceNewLandmarkAPI_H_








