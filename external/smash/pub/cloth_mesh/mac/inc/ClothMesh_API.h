#ifndef _SMASH_CLOTHMESHAPI_H_
#define _SMASH_CLOTHMESHAPI_H_

#include "smash_module_tpl.h"
#include "tt_common.h"

#ifdef __cplusplus
extern "C"
{
#endif // __cplusplus

/** 定义各种衣物单品类型 */
typedef enum {
    kShortSleevedShirt = 0,
    kLongSleevedShirt,
    
    kShortSleevedOutwear,//    "short_sleeved_outwear",
    kLongSleevedOutwear,//    "long_sleeved_outwear",
    kVest,//    "vest",
    kSling,//    "sling",
    
    kShorts,
    kTrousers,
    kSkirt,
    
    kShortSleeveDress,//    "short_sleeve_dress",
    kLongSleeveDress,//    "long_sleeve_dress",
    kVestDress,//    "vest_dress",
    
    kSlingDress,
    
    kClothTypesCount,
} ClothTypes;

typedef enum {
    UpCloth = 0,
    DownCloth = 1,
    IntegralCloth = 2,
} ClothCategory;
    
//最多的单件衣物顶点数量
#define MaxClothVerticesCount 128
//一次检测中最多得到的单件衣物数量
#define MaxClothPiecesPerFrame 16

/** 单件衣物检测结果 */
typedef struct {
    // 跟踪ID:
    int trackID;
    // 衣物类型，ClothTypes枚举值
    int type;
    float score;
    // 顶点数量（对于相同类型的衣物，一般应该是固定值）
    int verticesCount;
    // 包围框左上和右下坐标
    float x0;
    float y0;
    float x1;
    float y1;
    // 衣物顶点数组，按x，y依次打平存储
    float vertices[MaxClothVerticesCount * 2];
    // 每个顶点的置信度参考值
    float probs[MaxClothVerticesCount];
} ClothInfo;

// clang-format off
typedef void* ClothMeshHandle;

/**
 * @brief 模型枚举，有些模块可能有多个模型
 *
 */
typedef enum {
    kClothMeshModelDetect = 1,          ///全局检测
    kClothMeshModelTrack = 2,           ///跟踪
} ClothMeshModelType;


/**
 * @brief 封装预测接口的输入数据
 *
 * @note 不同的算法，可以在这里添加自己的数据
 */
typedef struct {
    ModuleBaseArgs base;           ///< 对视频帧数据做了基本的封装
    // 此处可以添加额外的算法参数
} ClothMeshArgs;


/**
 * @brief 封装预测接口的返回值
 *
 * @note 不同的算法，可以在这里添加自己的自定义数据
 */
typedef struct {
    int clothCount;
    ClothInfo clothInfos[MaxClothPiecesPerFrame];
} ClothMeshRet;
    
AILAB_EXPORT
const char* ClothMesh_GetClothTypeName(int typeID);
    
AILAB_EXPORT
int ClothMesh_GetClothCategory(int typeID);
    
AILAB_EXPORT
int ClothMesh_GetClothOutlineData(int index);
    
/**
 * @brief 创建句柄
 *
 * @param out 初始化的句柄
 * @return ClothMesh_CreateHandle
 */
AILAB_EXPORT
int ClothMesh_CreateHandle(ClothMeshHandle* out);


/**
 * @brief 从文件路径加载模型
 *
 * @param handle 句柄
 * @param type 需要初始化的句柄
 * @param modelPath 模型路径
 * @note 模型路径不能为中文、火星文等无法识别的字符
 * @return ClothMesh_LoadModel
 */
AILAB_EXPORT
int ClothMesh_LoadModel(ClothMeshHandle handle,
                         ClothMeshModelType type,
                         const char* modelPath);


/**
 * @brief 加载模型（从内存中加载，Android 推荐使用该接口）
 *
 * @param handle 句柄
 * @param type 初始化的模型类型
 * @param memModel 模型文件buf指针
 * @param modelSize buf文件的大小
 * @attention 调用方需要保证mem_model地址开始连续到model_size的内存是可读
 * @return ClothMesh_LoadModelFromBuff
 */
AILAB_EXPORT
int ClothMesh_LoadModelFromBuff(ClothMeshHandle handle,
                                 ClothMeshModelType type,
                                 const char* memModel,
                                 int modelSize);

/**
 * @brief 算法的主要调用接口
 *
 * @param handle
 * @param args
 * @param ret
 * @return AILAB_EXPORT ClothMesh_DO
 */
AILAB_EXPORT
int ClothMesh_DO(ClothMeshHandle handle,
                  ClothMeshArgs* args,
                  ClothMeshRet* ret);


/**
 * @brief 销毁句柄，释放资源
 *
 * @param handle
 * @return AILAB_EXPORT ClothMesh_ReleaseHandle
 */
AILAB_EXPORT
int ClothMesh_ReleaseHandle(ClothMeshHandle handle);

////////////////////////////////////////////
// 如果需要添加新接口，需要找工程组的同学 review 下
////////////////////////////////////////////
    
AILAB_EXPORT
void ClothMesh_PruneTrackingBoxes(ClothMeshHandle handle, int *prunedTrackIDs, int count);

AILAB_EXPORT
void ClothMesh_AddTrackingBox(ClothMeshHandle handle, int referenceBoxID, float normalizedOffsetX, float normalizedOffsetY, float scaleX, float scaleY);

AILAB_EXPORT
void ClothMesh_SetSmoothSigma(ClothMeshHandle handle, float smoothSigma);

AILAB_EXPORT
void ClothMesh_SetTrackingScoreThreshold(ClothMeshHandle handle, float threshold);
    
AILAB_EXPORT
void ClothMesh_SetDetectScoreThreshold(ClothMeshHandle handle, float threshold);
    
AILAB_EXPORT
void ClothMesh_SetEnlargeFactor(ClothMeshHandle handle, float factor);

AILAB_EXPORT
void ClothMesh_SetRectIouThreshold(ClothMeshHandle handle, float minIOU);

AILAB_EXPORT
void ClothMesh_SetDetectInterval(ClothMeshHandle handle, int interval);

AILAB_EXPORT
void ClothMesh_SetMinLastingFrames(ClothMeshHandle handle, int minLastingFrames);
    
AILAB_EXPORT
void ClothMesh_SetMinKeypointProb(ClothMeshHandle handle, float minKeypointProb);

AILAB_EXPORT
void ClothMesh_SetMinValidKeypointsProportion(ClothMeshHandle handle, float minValidKeypointsProportion);
    
#ifdef __cplusplus
}
#endif  // __cplusplus

// clang-format on
#endif // _SMASH_CLOTHMESHAPI_H_
