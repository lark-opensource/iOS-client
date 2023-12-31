//
// Created by liuzhichao on 2018/9/20.
//

#ifndef SMASH_FACE_FITTING_API2_H
#define SMASH_FACE_FITTING_API2_H

#include "tt_common.h"
#include "face_fitting_API.h"

#if defined __cplusplus
extern "C" {
#endif

//pack output
typedef struct FaceFittingResult2 {
    FaceFittingMeshInfo face_mesh_info[FITTING_MAX_FACE];
    int face_mesh_info_count;               //返回mesh的个数, 请使用face_mesh_info_count来取face_mesh_info的前几个的内容，不要越界！！
    FaceFittingMeshConfig face_mesh_config;
}FaceFittingResult2;

/**
 * @param handle            FaceFittingHandle
 * @return                  TT_OK or others
 */
AILAB_EXPORT
int FaceFitting_CreateHandle2(FaceFittingHandle *handle);

/**
 * invoke example:  FaceFitting_SetParam(handle, Solver_Lambda, 10000); 不调用的时候会采用默认的参数 default{Lambda = 10000, maxIter = 10, eps = 1, ratio = 0.025}
 * @param handle            FaceFittingHandle
 * @param type              FaceFittingParamType
 * @param value             value
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_SetParam2(FaceFittingHandle handle, FaceFittingParamType type, float value);

/**
 * @param model_path        模型文件的绝对路径
 * @param config            返回变量，返回当前模型的配置信息    参考 FaceFittingMeshConfig2的定义
 * @param model_type        FaceFittingModelType， model_typed应该与模型文件一一对应
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_InitModel2(FaceFittingHandle handle, const char *model_path, FaceFittingModelType model_type);


/**
 * @param handle            FaceFittingHandle
 * @param buf               内存数据
 * @param buf_len           长度
 * @param model_type        FaceFittingModelType， model_typed应该与模型文件一一对应
 * @param config            返回变量，返回当前模型的配置信息    参考 FaceFittingMeshConfig2的定义
 * @return sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_InitModelFromBuf2(FaceFittingHandle handle, const char *buf, unsigned int buf_len, FaceFittingModelType model_type);


/**
 * FaceFittingResult2结构 的free函数
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT int FaceFitting_FreeResultMemory(FaceFittingResult2 * result);

/**
 * 分配FaceFittingResult2结构的malloc函数， 使用该函数分配的空间，一定要使用FaceFitting_FreeResultMemory来释放
 * 若加载1256模型，为保证兼容性，仍会返回1220的结果
 * @return                  分配失败会返回 NULL
*/
AILAB_EXPORT FaceFittingResult2 * FaceFitting_MallocResultMemory(FaceFittingHandle handle);

/**
 * 分配FaceFittingResult2结构的malloc函数， 使用该函数分配的空间，一定要使用FaceFitting_FreeResultMemory来释放
 * 加载1256模型时，若要得到1256的结果，必须使用该函数
 * @return                  分配失败会返回 NULL
*/
AILAB_EXPORT FaceFittingResult2 * FaceFitting_MallocResultMemoryOriginal(FaceFittingHandle handle);

/**
 * 将result1 deep拷贝 到result2
 * @param result1           src 结构体
 * @param result2           dst 结构体
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT int FaceFitting_CopyResultMemory(const FaceFittingResult2 * result1, FaceFittingResult2 * result2);


/**
 * 输入人脸id和106点关键点，返回mesh信息，mesh点数由ret决定
 * @param handle            FaceFittingHandle
 * @param args              输入
 * @param ret               输出
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_DoFitting3dMesh2(FaceFittingHandle handle, const FaceFittingArgs* args, FaceFittingResult2* ret);

/**
 * 输入人脸id和106点关键点，直接获取mesh信息，必须在FaceFitting_DoFitting3dMesh2之后才能调用，mesh点数由ret决定
 * @param handle            FaceFittingHandle
 * @param args              输入
 * @param ret               输出
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_GetFittingResultOriginal(FaceFittingHandle handle, const FaceFittingArgs* args, FaceFittingResult2* ret);

/**
 * 为换脸模块增加的接口， 可以获得比普通模式更加准确的pose信息，速度会慢一些
 * @param handle
 * @param args
 * @param result
 * @return
 */
int FaceFitting_DoFitting3dMesh2ForSwapperMe(FaceFittingHandle handle, const FaceFittingArgs *args, FaceFittingResult2 *result);

/**
 * 释放内部资源，不使用的时候一定要调用
 * @param handle            调用后handle会重置为0
 * @return                  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_ReleaseHandle2(FaceFittingHandle *handle);


#if defined __cplusplus
};
#endif

#endif //SMASH_FACE_FITTING_API2_H
