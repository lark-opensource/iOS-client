//
//  bef_effect_composer.h
//  effect_sdk
//
//  Created by Stan Shen on 2018/7/18.
//

#ifndef bef_effect_composer_h
#define bef_effect_composer_h

#include "bef_effect_public_define.h"
#include "bef_effect_brush2d_define.h"
#include <stdbool.h>

/**
 * @brief Setup composer-effect with a specified string.(Deprecated)
 * @param handle          Effect handle
 * @param strPath    The absolute path of effect package.
 * @return                If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_composer(bef_effect_handle_t handle, const char *strPath);



/**
 * @brief Set Composer Mode
 * @param handle        Effect handle
 * @param mode          0: A+B slot mode (Composer Feature), 1: A+B+C slot mode
 * @param orderType     Sort by zorder, currently only supports 0
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_set_mode(bef_effect_handle_t handle, int mode, int orderType);

/**
* @brief Set composer node states
* @param handle        Effect handle
* @param nodePaths     Coexisting resource package path array
* @param nodeNum       The length of nodePaths
* @param stickerTags  whether the effect should be active
* @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_composer_set_states(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum, const bool states[]);

/**
 * @brief Set composer nodes
 * @param handle        Effect handle
 * @param nodePaths     Coexisting resource package path array
 * @param nodeNum       The length of nodePaths
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_set_nodes(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum);

/**
 * @brief Set composer nodes(with EffectSDK configuration)
 * @param handle        Effect handle
 * @param nodePaths     Coexisting resource package path array
 * @param nodeNum       The length of nodePaths
 * @param stickerTags   EffectSDK configuration information of sticker in the background
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_set_nodes_with_tags(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum, const char* stickerTags[]);

/**
 * @brief Reload composer nodes
 * @param handle        Effect handle
 * @param nodePaths     Array of resource package paths to be reloaded(Does not handle node paths that do not exist in Composer)
 * @param nodeNum       The length of nodePaths
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_reload_nodes(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum);

/**
 * @brief Reload composer nodes(with EffectSDK configuration)
 * @param handle        Effect handle
 * @param nodePaths     Array of resource package paths to be reloaded(Does not handle node paths that do not exist in Composer)
 * @param nodeNum       The length of nodePaths
 * @param stickerTags   EffectSDK configuration information of sticker in the background
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_reload_nodes_with_tags(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum, const char* stickerTags[]);

/**
 * @brief Add nodes to Composer
 * @param handle        Effect handle
 * @param nodePaths     Array of resource package paths to be added
 * @param nodeNum       The length of nodePaths
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_append_nodes(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum);

/**
 * @brief Add nodes to Composer(with EffectSDK configuration)
 * @param handle        Effect handle
 * @param nodePaths     Array of resource package paths to be addad
 * @param nodeNum       The length of nodePaths
 * @param stickerTags   EffectSDK configuration information of sticker in the background
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_append_nodes_with_tags(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum, const char* stickerTags[]);

/**
 * @brief Remove nodes from composer
 * @param handle        Effect handle
 * @param nodePaths     Array of node resource package paths to be deleted
 * @param nodeNum       The length of nodePaths
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_remove_nodes(bef_effect_handle_t handle, const char *nodePaths[], int nodeNum);

/**
 * @brief Replace composer nodes
 * @param handle        Effect Handle
 * @param oldPath       Old paths
 * @param newPath       new paths
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_replace_nodes(bef_effect_handle_t handle, const char *oldPaths[], int oldPathNum, const char *newPaths[], int newPathNum);

/**
 * @brief Replace composer nodes(with EffectSDK configuration)
 * @param handle         Effect Handle
 * @param oldPath        Old paths
 * @param newPath        new paths
 * @param newStickerTags EffectSDK configuration information of sticker in the background
 * @return               If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_replace_nodes_with_tags(bef_effect_handle_t handle, const char *oldPaths[], int oldPathNum, const char *newPaths[], int newPathNum, const char* newStickerTags[]);

/**
 * @brief Update Composer node parameters
 * @param handle        Effect handle
 * @param nodePath      Node resource package absolute path
 * @param nodeKey       Node key
 * @param nodeValue     Node value
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_update_node(bef_effect_handle_t handle, const char *nodePath, const char *nodeKey, float nodeValue);

/**
 * @brief Update Composer node parameters
 * @param handle        Effect handle
 * @param nodePath      Node resource package absolute path
 * @param nodeKey       Node key
 * @param nodeValue     Node json value
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_update_node_with_json(bef_effect_handle_t handle, const char *nodePath, const char *nodeKey, const char* jsonValue);
/**
 * @brief Update Composer multiple nodes parameters
 * @param handle        Effect handle
 * @param nodePathNum   Node count to update, must be length of below array `nodePaths`, `nodeKeys` and `nodeValues`
 * @param nodePaths     Array of nodes resource package absolute path
 * @param nodeKeys      Array of nodes key
 * @param nodeValues    Array of nodes value
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_update_multiple_nodes(bef_effect_handle_t handle, int nodePathNum, const char** nodePaths, const char** nodeKeys, const float* values);

/**
 * @brief Get the parameter value of the Composer node
 * @param handle        Effect handle
 * @param nodePath      Node resource package absolute path
 * @param nodeKey       Node key
 * @param nodeValue     Node value
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_get_node_value(bef_effect_handle_t handle, const char *nodePath, const char *nodeKey, float *nodeValue);

/**
 * @brief Get the absolute path of all nodes under composer, split with','.
 * @param handle        Effect handle
 * @param nodePaths     Returns a string containing the absolute paths of all nodes, with',' as the delimiter. The nodePath memory is created by effect and needs to be released by the caller
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_get_node_paths(bef_effect_handle_t handle, char **nodePath);

typedef struct _bef_composer_dump_result_st {
    char** nodePathTagValues;
    char** nodeTags;
    int count;
} bef_composer_dump_result;

/**
 * @brief Dump current all composer nodes information into dump_result, by two array of string nodePathTagValues and nodeTags
 * @param handle        Effect handle
 * @param dump_result   struct which will get composer information into it
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see bef_framework_public_constant_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_dump_nodes(bef_effect_handle_t handle, bef_composer_dump_result* dump_result);

/**
 * @brief Release memory pointed by bef_composer_dump_result::nodePathTagValues and bef_composer_dump_result::nodeTags, NOT the dump_result itself.
 * @param dump_result   struct to release, must be out param value from bef_effect_composer_dump_nodes WHEN it return SUCCESS(0)
 * @return              always success
 * @note                the dump_result struct itself will NOT be freed by this function. It should be allocated & deallocated by outside. This function just frees memory pointed by
 *                      bef_composer_dump_result::nodePathTagValues & bef_composer_dump_result::nodeTags allocated by EffectSDK.
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_release_dump_result(bef_composer_dump_result* dump_result);

/**
 * @brief Dump current composer mode and orderType, mode and orderType must be valid pointer with write permission.
 * @param handle        Effect handle
 * @param mode          int pointer to receive mode
 * @param orderType     int pointer to receive orderType
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see bef_framework_public_constant_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_dump_mode(bef_effect_handle_t handle, int* mode, int* orderType);

/**
 * @brief Compare the mutual exclusion relationship between new and old nodes on a key
 * @param handle        Effect handle
 * @param newNodePath   New resource path
 * @param oldNodePath   Old resource path
 * @param nodeTag       The tag to be compared by the client, if an empty string is passed, the first valid key is taken
 * @param result        0 is not mutually exclusive, 1 new node is mutually exclusive with old node, -1 new node is mutually exclusive with old node
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_exclusion_compare(bef_effect_handle_t handle, const char *newNodePath, const char *oldNodePath, const char *nodeKey, int *result);

/**
 * @brief Check if the composer node will be mutually exclusive on the key by the existing node
 * @param handle        Effect handle
 * @param nodePath      Resource path to be compared
 * @param nodeTag       The tag to be compared by the client, if an empty string is passed, the first valid key is taken
 * @param result        0 is not mutually exclusive, 1 is mutual exclusion of existing nodes, -1 will be mutually exclusive of existing nodes
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_composer_check_node_exclusion(bef_effect_handle_t handle,  const char *nodePath, const char *nodeTag, int *result);


/*************************************************************************************************/
//The following brush interfaces can only be called after the composer rendering chain is constructed (that is, after the first call to the bef_effect_process_texture() interface), otherwise the call will not take effect


/**
 * @brief Enable/disable the brush2d brush in the specified node
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @param bEnabled      true is enabled, otherwise disabled
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
    bef_effect_composer_set_brush2d_enabled
    (bef_effect_handle_t handle,const char *nodePath,bool bEnabled);

/**
 * @brief Set the brush2d parameters in the specified node
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @param param         brush parameters
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
    bef_effect_composer_set_brush2d_param
    (bef_effect_handle_t handle,const char *nodePath,const bef_brush2d_param *param);

/**
 * @brief Get the brush2d parameters in the specified node
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @param param         brush parameters
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_composer_get_brush2d_param
(bef_effect_handle_t handle,const char *nodePath,bef_brush2d_param *param);

/**
 * @brief Clear all brush2d strokes and history records in the specified node
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_composer_clear_brush2d_strokes
(bef_effect_handle_t handle,const char *nodePath);

/**
 * @brief Undo the previous step
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_composer_undo_brush2d_stroke
(bef_effect_handle_t handle,const char *nodePath);

/**
 * @brief Redo the previous step
 * @param handle        Effect handle
 * @param nodePaths     There are 2 forms: 1. Node resource absolute path 2. The absolute path of the node resource plus the brush name, separated by a colon, the format is path:filterName, When it is Case 1, this function is effective for all brushes under the composer package corresponding to path; when it is Case 2, it is effective for the brushes with the specified name
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effect_composer_redo_brush2d_stroke
(bef_effect_handle_t handle,const char *nodePath);

/**
 * @brief Get brush2d strokes
 * @param handle        Effect handle
 * @param nodePaths     Node resource package absolute path
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effct_composer_get_brush2d_strokes(bef_effect_handle_t handle, const char* nodePath, bef_brush2d_redo_undo* strokesData);
/**
 * @brief Set brush2d strokes
 * @param handle        Effect handle
 * @param nodePaths     Node resource package absolute path
 * @param bIncremental    Whether it is incremental mode
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effct_composer_set_brush2d_strokes(bef_effect_handle_t handle, const char* nodePath, bef_brush2d_redo_undo* strokesData, bool bIncremental);
/**
 * @brief Externally set the RGBA value of historical stroke data
 * @param rgba          RGBA float array, 4 elements
 * @param handle        Effect handle
 * @param nodePaths     Node resource package absolute path
 * @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
 */
BEF_SDK_API bef_effect_result_t
bef_effct_composer_set_strokes_rgba(bef_effect_handle_t handle,const char* nodePath, float* rgba, long long timestamp);
/**
* @brief Detect if the history brush overlaps the picture area displayed by VE
* @param ltrb      The four normalized coordinate values ​​of the left, top, right and bottom of the image displayed on the screen. By default, you should input {0.0, 0.0, 1.0, 1.0}
* @param handle        Effect handle
* @param nodePaths     Node resource package absolute path
* @param bOverlapped   Returns whether the stroke overlaps the screen display position
* @return              If succeed return BYTED_EFFECT_RESULT_SUC, other value please see byted_effect_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_composer_get_image_brush_overlapped(bef_effect_handle_t handle, const char* nodePath, float* ltrb, bool* bOverlapped);



/**
 * @brief Get intermediate cache results of custom algo algorithm
 * @param handle       Effect handle
 * @param nodePath     Node resource package absolute path
 * @param buff         Intermediate cache results
 */
BEF_SDK_API bef_effect_result_t bef_effect_get_custom_algo_data(bef_effect_handle_t handle, const char* nodePath,bef_custom_algo_data* buf);

/**
 * @brief Set the intermediate cache result of the custom algo algorithm from the outside, as the next input of the algorithm
 * @param handle       Effect handle
 * @param nodePath     Node resource package absolute path
 * @param buff         Intermediate cache results
 */
BEF_SDK_API bef_effect_result_t bef_effect_set_custom_algo_data(bef_effect_handle_t handle, const char* nodePath,const bef_custom_algo_data* buf);

#endif /* byted_effect_composer_h */
