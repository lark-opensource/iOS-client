/*
 * @Description: In User Settings Edit
 * @Author: your name
 * @Date: 2019-09-24 18:14:39
 * @LastEditTime: 2019-09-26 21:18:51
 * @LastEditors: Please set LastEditors
 */
//
//  bef_effect_mv_api.h
//  effect_sdk
//
//  Created by Helen on 2019/3/18.
//

#ifndef bef_effect_mv_api_h
#define bef_effect_mv_api_h

#include "bef_effect_api.h"
#include "bef_effect_public_business_mv_define.h"
#include <stdbool.h>

/**
 @brief Set whether to load resources synchronously

 @param handle effect_handle
 @param enable_sync true on, false off
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */

BEF_SDK_API bef_effect_result_t bef_effect_mv_set_should_sync(bef_effect_handle_t handle, bool enable_sync);


/**
 @brief Set the maximum time for resource loading

 @param handle effect_handle
 @param resource_load_timeout_us Unit us. This value will take effect on the next seek. When it is -1, it waits until the load is completed; when it is 0, it loads asynchronously and returns immediately.
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_resource_load_timeout_us(bef_effect_handle_t handle, int resource_load_timeout_us);

/**
@brief Set the beat tracking  para for template
 
@param handle effect_handle
@param beatTimes beat tracking times
@param beatValues beat tracking values
@param beatNum  size of beatTimes
@return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_beat_param(bef_effect_handle_t handle, const float* beatTimes, const int* beatValues, const int beatNum);

/**
 @brief Set the record param for package

 @param handle effect_handle
 @param recordParam the recorded param
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_record_param(bef_effect_handle_t handle, const char * recordParam);

/**
 @brief Set the mv template resource package path and existing user resources. Release the mv resource and set the path to null

 @param handle effect_handle
 @param template_path mv template resource package path
 @param user_resources existing user resources
 @param user_resources_count Number of user input resources
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_template_and_resources(bef_effect_handle_t handle, const char * template_path, bef_mv_resource_base_info *user_resources, int user_resources_count);


/**
 @brief Set the mv template resource package path and existing user resources. Release the mv resource and set the path to null

 @param handle effect_handle
 @param template_path mv template resource package path
 @param user_resources existing user resources
 @param user_resources_count Number of user input resources
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_template_and_resources_reload(bef_effect_handle_t handle, const char * template_path, bef_mv_resource_base_info *user_resources, int user_resources_count, bool is_reload);

/**
 @brief Obtain the current mv input information according to the set mv path
 @note 
 1) The memory pointed to by the info internal pointer is applied by the effect and held by the user. When not in use, the bef_effect_mv_free_info interface needs to be called to free the memory.
 2）The bef_effect_mv_free_info interface call only releases the memory pointed to by the pointer in info, does not empty bef_effect_mv_template_path to invalidate the mv template
 
 Demo：
 bef_mv_info info;
 bef_effect_mv_generate_info(effectHandle, &info);
 //...
 // use info
 //...
 bef_effect_mv_free_info(&info);

 @param handle effect_handle
 @param info Info data returned
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_generate_info(bef_effect_handle_t handle, bef_mv_info *info, bool toExport);
/**
 @brief When there is audio information in the MV template, you need to update the MV_info timeline
 
 @param handle effect_handle
 @param info    MV info
 @param inbuffer Audio pcm input data
 @param sampleRate Sampling Rate
 @param channels Number of channels
 @param sampleNum Number of sampling points
 @param audioType Audio type
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_update_info(bef_effect_handle_t handle, bef_mv_info *info, float *inbuffer, bef_mv_audio_update_info m_audio_update_info);

/**
 * @brief free mv info
 * 
 * @param info 
 * @return BEF_SDK_API bef_effect_mv_free_info 
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_free_info(bef_mv_info *info);


/**
 @param handle effect_handle
 @param timestamp The unit is second, time start is 0
 @param resources Input resources, which can be released after the method returns
 @param resources_count Number of resources
 @param audioType  Audio type
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_seek(bef_effect_handle_t handle, double timestamp, bef_mv_input_resource *resources, int resources_count, unsigned int output_texture);

/**
 @param handle effect_handle
 @param timestamp The unit is second, time start is 0
 @param resources Input resources, which can be released after the method returns
 @param resources_count Number of resources
 @param audioType  Audio type
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_seek_device_texture(bef_effect_handle_t handle, double timestamp, bef_mv_input_resource_device_texture* resources_device_texture, int resources_count, device_texture_handle output_device_texture);

/**
 @brief Get mv cache
 
 @param handle effect_handle
 @param mv_info_cache Stored MV cache
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */

BEF_SDK_API bef_effect_result_t bef_effect_mv_get_cache(bef_effect_handle_t handle, bef_mv_info_cache_c **mv_info_cache);
/**
 @brief Update mv cache
 
 @param handle effect_handle
 @param mv_info_cache MV cache
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_update_cache(bef_effect_handle_t handle, bef_mv_info_cache_c *mv_info_cache);
/**
 @brief free MV cache

 @param mv_info_cache Need to free the cache
 @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_free_cache(bef_mv_info_cache_c *mv_info_cache);
/**
 * @brief Save the algorithm result as a picture
 * 
 * @param handle Effect handle
 * @param photoPath User-selected pictures
 * @param algorithmType The type of algorithm should be consistent with the result in bef_mv_algorithm_config
 * @param maskPath Image path returned by the server
 * @return BEF_SDK_API bef_effect_mv_set_external_algorithm_result_image
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_external_algorithm_result_image(bef_effect_handle_t handle, const char *photoPath, const char *algorithmType, const char *resultImagePath);



/**
 * @brief Set algorithm result
 *
 * @param handle Effect handle
 * @param photoPath User-selected pictures
 * @param algorithmType The type of algorithm should be consistent with the result in bef_mv_algorithm_config
 * @param maskPath Image path returned by the server
 * @param type The type of result returned by the server
 * @return BEF_SDK_API bef_effect_mv_set_external_algorithm_result_image
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_external_algorithm_result(bef_effect_handle_t handle, const char *photoPath, const char *algorithmType, const char *result, bef_mv_algorithm_result_in_type type);


/**
 * @brief Get the algorithm information of the current MV template
 * 
 * @param handle  Effect handle
 * @param config Secondary pointer for storing algorithm configuration information
 * @return BEF_SDK_API bef_effect_mv_get_algorithms_config 
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_get_algorithms_config(bef_effect_handle_t handle, bef_mv_algorithm_config **config);

/**
 * @brief Get the algorithm information of the specified template
 * 
 * @param templatePath Template resource path
 * @param image_paths_size The length of iamge_paths array
 * @param iamge_paths User-selected array of image paths
 * @param config Algorithm information, output parameters
 * @return BEF_SDK_API bef_effect_mv_get_algorithms_config_with_path 
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_get_algorithms_config_with_path(const char* templatePath, size_t image_paths_size,char **iamge_paths,bef_mv_algorithm_config **config);

/**
 * @brief Get the algorithm information of the specified template
 *
 * @param templatePath Template resource path
 * @param image_paths_size The length of iamge_paths array
 * @param iamge_paths User-selected array of image paths
 * @param config_json  Algorithm information, output parameters
 * @return BEF_SDK_API bef_effect_mv_get_algorithms_config_with_path
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_get_algorithms_json_with_path(const char* template_path, size_t image_paths_size, char **image_paths, const char** config_json);
/**
 * @brief Release config structure, *config will become nullptr after calling
 * 
 * @param config Algorithm configuration structure secondary pointer
 * @return BEF_SDK_API bef_effect_mv_release_sever_algorithms_config 
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_release_sever_algorithms_config(bef_mv_algorithm_config **config);

BEF_SDK_API bef_effect_result_t bef_effect_mv_check_resource_integrity(const char* path);

/**
 * @brief Set the expected duration of the template
 *
 * @param handle  effect handle
 * @param duration Expected duration
 * @return BEF_SDK_API bef_effect_mv_free_info
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_duration(bef_effect_handle_t handle, double duration);

/**
 * @brief According to the parameter path to obtain the current mv each user input resource duration, stored in info->resources
 * @note The memory pointed to by the info internal pointer is applied by the effect and held by the user. When not in use, the bef_effect_mv_free_info interface needs to be called to free the memory.

 Demo:
 bef_mv_info info;
 bef_effect_mv_generate_info_with_path(path, &info);
 //...
 // use info
 //...
 bef_effect_mv_free_info(&info);

 * @param path Resource package path
 * @param info Info data returned
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_generate_info_with_path(const char *path, bef_mv_info *info);


/**
 * @brief Set the extra param for template, call it right after bef_effect_mv_template_and_resources if needed.
 *
 * @param handle  effect handle
 * @param content extra param content
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_extra_param(bef_effect_handle_t handle, const char* content);

/**
 * @brief Set the mv template render resolution
 * @param handle effect_handle
 * @param width resolution width
 * @param height resolution height
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_resolution(bef_effect_handle_t handle, int width, int height);

/**
 * @brief Get the mv text replace info
 * @param handle effect_handle
 * @param info result info
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_get_template_text_replace_info(bef_effect_handle_t handle, bef_mv_text_replace_info* info);

/**
 * @brief Free the mv text replace info
 * @param handle effect_handle
 * @param info result info to free
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_free_template_text_replace_info(bef_mv_text_replace_info* info);

/**
 * @brief Set the duration of each resource. Variable duration templates will use this function. Called before bef_effect_mv_template_and_resources
 * @param handle effect_handle
 * @param resource_durations Input resource duration array. The order of the array should be the same as the parameter user_resources of bef_effect_mv_template_and_resources
 * @param resource_durations_count resource_durations array length
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_resource_durations(bef_effect_handle_t handle, const float* resource_durations, const int resource_durations_count);

/**
 * @brief Set the expected duration of the variable template. . Called before bef_effect_mv_template_and_resources
 * @param handle  effect handle
 * @param duration Expected duration
 * @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_variable_duration(bef_effect_handle_t handle, float duration);

/**
* @brief MV set AERender MSAA mode
* @param handle effect handle.
* @param enable If ture, enable MSAA.
* @return If succeed return BEF_RESULT_SUC, other value please see bef_effect_base_define.h
*/
BEF_SDK_API bef_effect_result_t bef_effect_mv_set_enable_msaa(bef_effect_handle_t handle, bool enable);

#endif /* bef_effect_mv_api_h */
