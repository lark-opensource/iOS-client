//
//  bef_effect_face_clusting.h
//  Pods
//
//  Created by bytedance on 2019/10/10.
//

#ifndef bef_effect_face_clusting_h
#define bef_effect_face_clusting_h

#include "bef_effect_public_define.h"

typedef void*  bef_FaceClustingHandle;
typedef void* VECTOR_VECTOR_INT; // Represents vector<vector<int>>
typedef void* MAP_INT_VECTOR_INT; // Represents map<int,vector<int>>
typedef void* VECTOR_INT; // Represents vector<int>

typedef enum bef_fc_ParamType{
    bef_RecognitionfThreshold = 1, // Face recognition threshold, the larger the value, the higher the recall, the default value is 0.3
    bef_FeatureDim = 2,            // default is 128
    // Threshold of the distance between two temporary classes merged during clustering, default 0.943
    bef_ClustingThreshold = 3,
    bef_LinkageType = 4,           // Link method, default AvgLinkage
    bef_DistanceType = 5,          // Distance measurement method, default EUCLIDEAN
    bef_HP1 = 6,                   // Super parameter, default 0.895
    bef_HP2 = 7,                   // Super parameter, default 0.29
    bef_HP3 = 8,                   // Super parameter, default 0.885  to merge batch clusters
    bef_HP4 = 9,                   // Super parameter, default 0.29   to merge batch clusters
    bef_ClustingThreshold2 = 10,   // Clustering threshold, default 0.943, to merge batch clusters
    bef_BatchSize = 11,            // Batch size, default 2000. The smaller, the smaller the memory footprint, but usually the slower the speed
    bef_MaxMergeRound = 12,        // Maximum number of merges in batch clustering, default 10. The minimum value is 1, the larger the value, the slower the speed and the higher the accuracy
}bef_fc_param_type;


typedef enum bef_fc_DistanceType {
    bef_EUCLIDEAN = 1,       // Euclidean distance
    bef_COSINE = 2,          // Cosine distance(default)
    bef_BHATTACHARYYAH = 3,  // Pap distance
} bef_fc_distance_type;


typedef enum fc_LinkType {
    bef_AVERAGE_LINKAGE = 1,  /* choose average distance  default*/
    bef_CENTROID_LINKAGE = 2, /* choose distance between cluster centroids */
    bef_COMPLETE_LINKAGE = 3, /* choose maximum distance */
    bef_SINGLE_LINKAGE = 4,   /* choose minimum distance */
} bef_fc_link_type;

/**
 *@brief Load the cluster model
 *@note No need to set when only doing character clustering
 *@note Different models can be set according to the number of recognized characters
 *
 **/
BEF_SDK_API
int bef_FaceClusting_SetModel_path(bef_FaceClustingHandle handle, const char *model_path);

BEF_SDK_API int bef_FaceClusting_SetModel(bef_FaceClustingHandle handle,bef_resource_finder finder);

BEF_SDK_API
int bef_FaceClusting_SetModelFromBuf(bef_FaceClustingHandle handle, const char *model_buf, const int model_size);

/**
 * @brief Set the parameters, the default is already adjusted, if you need to adjust, please contact the RD of labcv
*/
BEF_SDK_API
int bef_FaceClusting_SetParamF(bef_FaceClustingHandle handle, bef_fc_param_type type, float value);

/*
 * @brief create handle
 */

BEF_SDK_API
int bef_FaceClusting_CreateHandler(bef_FaceClustingHandle *out);

/**
 *@brief Face feature clustering
 *@param features         Facial feature, the size is num_samples * FACE_FEATURE_DIM
 *@param num_samples      The number of faces
 *@param cluster         Output face clustering results
 */
BEF_SDK_API
int bef_FaceClusting_DoClustering(bef_FaceClustingHandle handle,
                              float *const features,
                              const int num_samples,
                              VECTOR_VECTOR_INT clusters);

/**
 *@brief Face feature clustering, batching to reduce memory usage
 *@param features         Facial feature，the size is num_samples * FACE_FEATURE_DIM
 *@param num_samples      The number of faces
 *@param cluster          Output face clustering results
 */
BEF_SDK_API
int bef_FaceClusting_DoClusteringBatch(bef_FaceClustingHandle handle,
                                   float *const features,
                                   const int num_samples,
                                   VECTOR_VECTOR_INT clusters);

/**
 * @brief Incremental face feature clustering
 * @param old_features          Existing facial features, the size is old_num_smaples * FACE_FEATURE_DIM
 * @param old_num_smaples       The number of existing faces
 * @param old_clusters          Existing face clustering, key is the cluster id, value is the index of old_features
 * @param new_features          Added facial features, the size is new_num_samples * FACE_FEATURE_DIM
 * @param new_num_samples       The number of new faces
 * @param incremental_clusters  Output face clustering results, key is the cluster id, value is the index of new_features
 * @note This is the result of the increment, and it is the full result after merging with old_clusters
 */
BEF_SDK_API
int bef_FaceClusting_DoIncrementallyClusting(bef_FaceClustingHandle handle,
                                         const float *old_features,
                                         const int old_num_smaples,
                                         const MAP_INT_VECTOR_INT old_clusters,
                                         const float *new_features,
                                         const int new_num_samples,
                                         MAP_INT_VECTOR_INT incremental_clusters);

/*
 *@brief Face recognition
 *@param features         Facial features，the size is num_samples * FACE_FEATURE_DIM
 *@param num_samples      The number of face
 *@param results          Face recognition results, -1: Non-targeted person, other: recognized person ID
 */
BEF_SDK_API
int bef_FaceClusting_DoRecognition(bef_FaceClustingHandle handle,
                               float *const features,
                               const int num_samples,
                               VECTOR_INT results);

/**
 *@brief release handle
 */
BEF_SDK_API
int bef_FaceClusting_ReleaseHandle(bef_FaceClustingHandle handle);

#endif /* bef_effect_face_clusting_h */
