//
// Created by liuzhichao on 2018/9/20.
//

#ifndef SMASH_FACE_FITTING_API_H
#define SMASH_FACE_FITTING_API_H

#include "tt_common.h"

#if defined __cplusplus
extern "C" {
#endif

typedef void *FaceFittingHandle;

//manager memory by sdk， count与num的解释：count表示数组的长度，num表示数组具有多少元素， 例如 一个2d坐标点(x,y)数组  [x,y,x,y,x,y,x,y]  ===> count = 8, num = 4
typedef struct FaceFittingMeshInfo {
    int id;                     // 人脸sdk返回的id，用来表示这个mesh属于哪一个人脸
    float* vertex;        // 3d模型的顶点,  由sdk管理内存分配与释放
    int vertex_count;           // vertex数组的长度
    float* landmark;      // 3d模型投影会图像坐标的landmark坐标值数组. 由sdk管理内存分配与释放
    int landmark_count;         // landmark数组的长度
    float* param;         // 解优化的参数，[scale，rotatex, rotatey, rotatez, tx, ty, alpha0, alpha1 ......], manager memory by sdk
    int param_count;            // param数组的长度
    float mvp[16];              // 将vertex变为ndc坐标的矩阵
    float model[16];            // 包括了对原始模型的旋转平移缩放的模型矩阵         正交投影下使用
    float * normal;       // 模型空间下的法线， 长度和vertex_count是一样的,   由sdk管理内存分配与释放
    float * tangent;      // 模型空间下的切线， 长度和vertex_count是一样的,   由sdk管理内存分配与释放
    float * bitangent;    // 模型空间下的副切线， 长度和vertex_count是一样的,  由sdk管理内存分配与释放
    float rvec[3];              // opencv solvepnp输出的旋转向量
    float tvec[3];              // opencv solvepnp输出的平移向量
} FaceFittingMeshInfo;


//与模型文件一一对应, 内容不会改变的， 由sdk管理内存分配与释放
typedef struct FaceFittingMeshConfig {
    int version_code;                           // 模型的版本号
    float* uv;                            // 标准展开图像的 uv坐标, 由sdk管理内存分配与释放
    int uv_count;                               // uv数组的长度
    unsigned short* flist;                // 3d模型顶点 的索引数组(face),  由sdk管理内存分配与释放
    int flist_count;                            // flist数组的长度
    unsigned short* landmark_triangle;    // landmark做三角剖分后的三角形数组,    由sdk管理内存分配与释放
    int landmark_triangle_count;                // landmark数组的长度

    int num_vertex;                             // = uv_count/2 = vertex_count/3    表示顶点元素的个数，      uv是标准3d模型的展开后的2d坐标
    int num_flist;                              // = flist_count / 3                面的个数
    int num_landmark_triangle;                  // = landmark_triangle_count / 2    三角形的个数
    int mum_landmark;                           // = landmark_count / 3             landmrk的个数
    int num_param;                              // = param_count                    求解参数的个数
} FaceFittingMeshConfig;


#define FITTING_MAX_FACE 6 //最大支持的人脸数

// pack landmark
typedef struct FaceFittingLandmarkInfo {
    int id;                     // 人脸的id
    AIPoint * landmark106; ;     // 106点数组               required
    bool eye_lv2;              // true 使用二级网络的眼睛             optional
    bool eyebrow_lv2;          // true 使用二级网络的眉毛             optional
    bool lips_lv2;             // true 使用二级网络的嘴巴             optional
    bool iris_lv2;             // true 使用二级网络的iris             optional
    AIPoint * eye_left;       // 左眼关键点                  optional
    AIPoint * eye_right;      // 右眼关键点                  optional
    AIPoint * eyebrow_left;   // 左眉毛关键点                 optional
    AIPoint * eyebrow_right;  // 右眉毛关键点                 optional
    AIPoint * lips;           // 嘴唇关键点                  optional
    AIPoint * left_iris;      // 左虹膜关键点             optional
    AIPoint * right_iris;     // 右虹膜关键点             optional
} FaceFittingLandmarkInfo;


// pack input
typedef struct FaceFittingArgs {
    FaceFittingLandmarkInfo face_landmark_info[FITTING_MAX_FACE];
    int face_landmark_info_count;                   //输入的人脸的个数
    int view_width;
    int view_height;
    float cameraParams[3];          // focal_length, centerx, centery
}FaceFittingArgs;


//pack output
typedef struct FaceFittingResult {
    FaceFittingMeshInfo face_mesh_info[FITTING_MAX_FACE];
    int face_mesh_info_count;               //返回mesh的个数, 请使用face_mesh_info_count来取face_mesh_info的前几个的内容，不要越界！！！
}FaceFittingResult;


/** faceu与effect使用的不是一个模型，这里判断一下使用哪个模型，
 * Model_845        tt_facefitting845_v2.1.model
 * Model_1220      tt_facefitting1220_v2.0.model
 * Model_1256      tt_facefitting1256_v1.0.model
 */
typedef enum FaceFittingModelType {
    Model_845,
    Model_1220,
    Model_1256,
} FaceFittingModelType;

typedef enum FaceFittingCameraType {
    Camera_Orthographic = 0,
    Camera_Perspective = 1
} FaceFittingCameraType;

typedef enum FaceFittingParamType {
    Solver_Lambda = 1,      // Solver parameter
    Solver_MaxIter = 2,
    Solver_Eps = 3,
    Solver_Ratio = 4,
    Solver_Smooth = 5,
    Solver_Camera_Type = 6,
    Config_Cal_TB = 7,
    Eyelash_Flag = 8,
    Use_Semantic_Lmk = 9,
    Mouth_BS_Limit = 10
} FaceFittingParamType;

/**
 * @param handle
 * @return  TT_OK or others
 */
AILAB_EXPORT
int FaceFitting_CreateHandle(FaceFittingHandle *handle);

/**
 * invoke example:  FaceFitting_SetParam(handle, Solver_Lambda, 10000);
 * 不调用的时候会采用默认的参数 default{Lambda = 10000, maxIter = 10, eps = 1, ratio = 0.025}
 * @param handle
 * @param type      FaceFittingParamType
 * @param value     value
 * @return    sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_SetParam(FaceFittingHandle handle, FaceFittingParamType type, float value);

/**
 * @param model_path    模型文件的绝对路径
 * @param config    返回变量，返回当前模型的配置信息    参考 FaceFittingMeshConfig的定义
 * @param model_type        FaceFittingModelType， model_typed应该与模型文件一一对应
 * @return  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_InitModel(FaceFittingHandle handle, const char *model_path, FaceFittingModelType model_type, FaceFittingMeshConfig *config);


/**
 * @param handle
 * @param buf
 * @param buf_len
 * @param model_type         FaceFittingModelType， model_typed应该与模型文件一一对应
 * @param config             返回变量，返回当前模型的配置信息    参考 FaceFittingMeshConfig的定义
 * @return sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_InitModelFromBuf(FaceFittingHandle handle, const char *buf, unsigned int buf_len, FaceFittingModelType model_type, FaceFittingMeshConfig *config);



/**
 * 输入人脸id和106点关键点，返回mesh信息
 * @param handle
 * @param args  输入
 * @param ret   输出
 * @return  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_DoFitting3dMesh(FaceFittingHandle handle, const FaceFittingArgs* args, FaceFittingResult* ret);

/**
 * 释放内部资源，不使用的时候一定要调用
 * @param handle    调用后handle会重置为0
 * @return  sucessed TT_OK or failed others
 */
AILAB_EXPORT
int FaceFitting_ReleaseHandle(FaceFittingHandle *handle);


#if defined __cplusplus
};
#endif

#endif //SMASH_FACE_FITTING_API_H
