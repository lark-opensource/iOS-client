#ifndef _SMASH_HEAD3DAPI_H_
#define _SMASH_HEAD3DAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"
#include "FaceSDK_API.h"
#include "FaceNewLandmark_API.h"
#include "EarSeg_API.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

// clang-format off
typedef void *Head3dHandle;

#define HEAD3D_NUM_VERTICES 2541//2788
#define HEAD3D_NUM_FACES 5004//5422
#define HEAD3D_MAX_SUPPORT 5
#define HEAD3D_NUM_LMK 89

/**
 * @brief 模型参数类型
 *  pFov         相机视场角，默认65.5
 *  pZnear       相机近平面，默认0.01m
 *  pZfar        相机远平面，默认10m
 *  pScale       人头缩放尺度，默认1，对应单位m；设为100，对应单位cm
 *  pEnableEar   启用耳朵关键点，0或1，默认0关闭
 *  pEnableDelay 启用延迟帧模式，0或1，默认0关闭
 *  pDelayFrames 延迟帧的帧数，默认3
 *  pShapeMorphLimit 形变能力限制权重，大于0，默认3；值越小贴合性越好，抖动性加剧；反之亦然
 *  pExpMorphLimit   形变能力限制权重，大于0，默认6；值越小表情的贴合性越好，抖动性加剧；反之亦然
 *  pEarClsThr       耳朵遮挡分类的阈值，默认0.1
 *  pCalRealSize     计算瞳距，以及人头的真实尺寸，每次人脸进入图像会重新计算，0或1，默认0关闭
 *  pCalRealSizeOnce 同上，但只计算一次，当置为1时会触发一次计算
 */
typedef enum {
    pFov = 1,
    pZnear = 2,
    pZfar = 3,
    pScale = 4,
    pEnableEar = 5,
    pEnableDelay = 6,
    pDelayFrames = 7,
    pShapeMorphLimit = 8,
    pExpMorphLimit = 9,
    pEarClsThr = 10,
    // 以下为平滑系数
    // 目前仅用于算法调试
    pShapePsig = 11,
    pExpPsig = 12,
    pRPsig = 13,
    pTxyPsig = 14,
    pTzPsig = 15,
    // 真实大小参数
    pCalRealSize = 16,
    pCalRealSizeOnce = 17,
} Head3dParamType;


/**
 * @brief 模型枚举，有些模块可能有多个模型
 *  kHead3dModel1   网络模型
 *  kHead3dObj      blendshapes模型
 */
typedef enum {
    kHead3dModel1 = 1,           ///< 网络模型，已废弃
    kHead3dObj = 2,              ///< blendshapes模型，已废弃
    kHead3dFittingObj = 3,              ///< For fitting 模型
    kHead3dFittingExternalObj = 4,              ///< For fitting 模型
} Head3dModelType;


/**
 * @brief 封装预测接口的输入数据
 */
typedef struct Head3dArgs {
    ModuleBaseArgs base;        ///< 对视频帧数据做了基本的封装
    AIFaceInfo *face_info;      ///< 原始图像上的人脸SDK检测结果
    float camera_matrix[3];     ///< 相机的内参   [focal cx cy]
} Head3dArgs;

/**
 * @brief 封装预测接口的额外输入数据
 */
typedef struct Head3dExternalArgs {
    FaceOutline_Output *nl_output;
    EarSegOutput *ear_output;
} Head3dExternalArgs;

/**
 * @brief 单个人脸的顶点、法线、mvp等信息
 * @note vertex normal tangent bitangent 都是相同大小的数组，数组的长度是vertices_count
 */
typedef struct Head3dInfo {
    int id;                         ///< 同一个人头的标志与facesdk中的id是一致的
    float *vertex;                  ///< 顶点位置
    float *normal;                  ///< 模型空间下的法线   长度和vertex_count是一样的
    float *tangent;                 ///< 模型空间下的切线   长度和vertex_count是一样的
    float *bitangent;               ///< 模型空间下的副切线  长度和vertex_count是一样的
    int vertex_count;               ///< vertex数组的大小
    
    float *uv;                      ///< uv数组 比较复杂
    int uv_count;                   ///< uv数组的大小
    
    unsigned short *triangle;       ///< 组成mesh的的三角形索引
    int triangle_count;             ///< triangle数组的大小
    
    float mvp[16];                  ///< mvp = project * model * view， 4x4行的矩阵
    float model[16];
    float view[16];
    float project[16];
    bool valid;                     ///< 表示这个Head3dInfo中的信息否有效， 有效为true，无效为false
    
    float *vertex_test;             ///< 顶点位置
    float *landmarks_2d;            ///<输入的2d关键点
    float *project_2d;              ///<3d关键点的投影点
    float pupil_dist;
}Head3dInfo;


/**
 * @brief 封装预测接口的返回值
 * @note 算法的返回结果, head_count与head_count_alloced的区别
 * head3d_infos_alloced 表示我们使用 Head3d_MallocResultMemory函数为Head3dRet分配了多少个Head3dInfo的空间,
 * 释放时候会根据head_count_alloced数值来释放空间
 * head_count表示该返回结果中包括了多少个有效的人头信息， 每一帧中可能是变化的
 * 他们的关系如下。HEAD3D_MAX_SUPPORT >= head3d_infos_alloced >= head3d_infos_count
 */
typedef struct Head3dRet {
    Head3dInfo * head3d_infos;      ///< Head3dInfo 数组， 参考Head3dInfo参考含义
    int head3d_infos_count;         ///< 当前结果中有效的Head3dInfo的个数
    int head3d_infos_alloced;       ///< 分配的Head3dInfo个数
}Head3dRet;


/**
 * @brief 创建句柄
 * @param out 初始化的句柄
 * @return Head3d_CreateHandle  success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_CreateHandle(Head3dHandle *out);


/**
 * @brief 从文件路径加载模型
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param model_path 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return Head3d_LoadModel success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_LoadModel(Head3dHandle handle, Head3dModelType type, const char *model_path);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param mem_model 模型文件buf指针
 * @param model_size buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return Head3d_LoadModelFromBuff     success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_LoadModelFromBuff(Head3dHandle handle, Head3dModelType type, const char *mem_model, int model_size);


/**
 * @brief 配置 int/float 类型的算法参数，该接口为轻量级接口，可以在调用 #{MODULE}_DO接口进行更换
 * @param handle 句柄
 * @param type 设置参数的类型
 * @param value 设置参数的值
 * @return Head3d_SetParamF     success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_SetParamF(Head3dHandle handle, Head3dParamType type, float value);


/**
 * @brief 算法的主要调用接口
 *
 * @param handle    句柄
 * @param args      输入封装
 * @param ret       返回结果
 * @return AILAB_EXPORT Head3d_DO   success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_DO(Head3dHandle handle, Head3dArgs *args, Head3dRet *ret);


AILAB_EXPORT
int Head3d_Fitting(Head3dHandle handle, Head3dArgs *args, Head3dExternalArgs *external_args, Head3dRet *ret);


/**
 * @brief 销毁句柄，释放资源
 * @param handle
 * @return AILAB_EXPORT Head3d_ReleaseHandle
 */
AILAB_EXPORT
int Head3d_ReleaseHandle(Head3dHandle handle);


/**
 * @brief 打印该模块的参数，用于调试
 * @param handle
 * @return AILAB_EXPORT Head3d_DbgPretty
 */
AILAB_EXPORT
int Head3d_DbgPretty(Head3dHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////

/**
 * @brief 分配Head3dRet结构的malloc函数， 使用该函数分配的空间，一定要使用FaceFitting_FreeResultMemory来释放
 * @param handle
 * @param num 为Head3dRet中的head3d_infos分配几个数据。如果分配成功会把num保存在Head3dRet中的head3d_infos_alloced中
 * @return      分配失败会返回 NULL
 */
AILAB_EXPORT
Head3dRet * Head3d_MallocResultMemory(Head3dHandle handle, int num);


/**
 * @brief 执行深拷贝， 将result1 内容拷贝 到result2
 * @param result1    Head3d_MallocResultMemory分配的空间
 * @param result2    Head3d_MallocResultMemory分配的空间
 * @return      success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_CopyResultMemory(const Head3dRet * result1, Head3dRet * result2);


/**
 * @brief 释放由Head3d_MallocResultMemory分配的空间
 * @param result
 * @return  success SMASH_OK, others see tt_common.h
 */
AILAB_EXPORT
int Head3d_FreeResultMemory(Head3dRet * result);

#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_HEAD3DAPI_H_
