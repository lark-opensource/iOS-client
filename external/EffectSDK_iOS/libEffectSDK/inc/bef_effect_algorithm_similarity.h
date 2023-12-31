//
//  bef_effect_algorithm_similarity.h
//  Pods
//
//  Created by lvshaohui1234 on 2019/10/11.
//

#ifndef bef_effect_algorithm_similarity_h
#define bef_effect_algorithm_similarity_h

#include "bef_effect_public_define.h"
#ifdef BEF_MODULE_HANDLE
#undef BEF_MODULE_HANDLE
#endif
#define BEF_MODULE_HANDLE bef_SimilarityHandle

typedef void* BEF_MODULE_HANDLE;

/**
 * @brief Model enumeration, some modules may have multiple models
 *
 */
typedef enum  {
    bef_kSimilarityModel1 = 1,
}bef_SimilarityModelType;

// Model parameter type
typedef enum  {
    bef_THRES,  // Judgment threshold of picture similarity
}bef_SimilarityParamType;

typedef struct BEF_Feature {
    char* feature_data;  // Featured binary data
    int feature_len;     // Feature data length
} BEF_Feature;

// Create handle
BEF_SDK_API int bef_Similarity_CreateHandle(BEF_MODULE_HANDLE* out);

/**
 * @brief Load model from file path
 *
 * @param handle
 * @param type Model type
 * @param model_path Model path
 * @return Similarity_LoadModel
 */
BEF_SDK_API
int bef_Similarity_LoadModel_path(BEF_MODULE_HANDLE handle,
                         bef_SimilarityModelType type,
                         const char* model_path);
BEF_SDK_API int bef_Similarity_LoadModelFromBuff(BEF_MODULE_HANDLE  handle,
                                  bef_SimilarityModelType type,
                                  const char* mem_model,
                                  int model_size);

BEF_SDK_API int bef_Similarity_LoadModel(BEF_MODULE_HANDLE handle,
                                  bef_SimilarityModelType type,
                                  bef_resource_finder finder);

// Configure int/float algorithm parameters. This interface is a lightweight interface, which can be replaced by calling #{MODULE}_DO interface
BEF_SDK_API int bef_Similarity_SetParamF(BEF_MODULE_HANDLE handle,
                                      bef_SimilarityParamType type,
                                      float value);

// Configure char* algorithm parameters. This interface is a lightweight interface, which can be replaced by calling #{MODULE}_DO interface
BEF_SDK_API int bef_Similarity_SetParamS(BEF_MODULE_HANDLE handle,
                                      bef_SimilarityParamType type,
                                      char* value);

///////////////////////////////////////////////////
////////////  1. Similarity score of two images
///////////////////////////////////////////////////
// Input parameters
typedef struct BEF_SimilarityArgs {
    BEF_Feature* fea1;
    BEF_Feature* fea2;
}BEF_SimilarityArgs;

// Return value
typedef struct BEF_SimilarityRet {
    float score;  //Similarity score of two images
}BEF_SimilarityRet;

// Algorithm main call interface
BEF_SDK_API int bef_Similarity_DO(BEF_MODULE_HANDLE handle,
                               BEF_SimilarityArgs* args,
                               BEF_SimilarityRet* ret);

///////////////////////////////////////////////////
////////////  2. Extract image features
///////////////////////////////////////////////////
// Input parameters
typedef struct BEF_SimilarityFeatureArgs {
    bef_ModuleBaseArgs img;
}BEF_SimilarityFeatureArgs;

// Return value
typedef struct BEF_SimilarityFeatureRet {
    // Memory is allocated by SDK and released by caller
    BEF_Feature fea;  // Extracted features
}BEF_SimilarityFeatureRet;

// Algorithm main call interface
/**
 @param args is the binary data of the image.
 @param ret Binary features of the image.
 */
BEF_SDK_API int bef_Similarity_Feature(BEF_MODULE_HANDLE handle,
                                    BEF_SimilarityFeatureArgs* args,
                                    BEF_SimilarityFeatureRet* ret);

// Free up binary data memory for image features
BEF_SDK_API int bef_Similarity_Feature_Destroy(BEF_MODULE_HANDLE handle,
                                            BEF_SimilarityFeatureRet* ret);

///////////////////////////////////////////////////
////////////  3. Cluster album images
///////////////////////////////////////////////////
// Input parameters
typedef struct BEF_SimilarityClusterArgs {
    BEF_Feature* features;
    int n_features;
}BEF_SimilarityClusterArgs;

// Return value
typedef struct BEF_SimilarityClusterRet {
    // Memory is allocated by SDK and released by caller
    int* cluster_ids;  // Length is n_features, images with the same id are similar images
}BEF_SimilarityClusterRet;

BEF_SDK_API int bef_Similarity_Cluster(BEF_MODULE_HANDLE handle,
                                    BEF_SimilarityClusterArgs* args,
                                    BEF_SimilarityClusterRet* ret);

// Destroy handle
BEF_SDK_API int bef_Similarity_ReleaseHandle(BEF_MODULE_HANDLE handle);

// Print the parameters of the module for debugging
BEF_SDK_API int bef_Similarity_DbgPretty(BEF_MODULE_HANDLE handle);


#endif /* bef_effect_algorithm_similarity_h */
