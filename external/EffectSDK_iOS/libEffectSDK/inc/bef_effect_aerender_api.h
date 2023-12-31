//
//  bef_effect_aerender_api_h
//
//  Created by bytedance on 09/18/2020.
//

#ifndef bef_effect_aerender_api_h
#define bef_effect_aerender_api_h

#include "bef_framework_public_base_define.h"

typedef void* bef_aerender_handle_t;


/**
 * @brief Create aerender handle.
 * @param handle    Aerender handle that will be created.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_create(bef_aerender_handle_t* handle);


/**
 * @param handle    Aerender handle that will  destroy
 */
BEF_SDK_API void bef_effect_aerender_destroy(bef_aerender_handle_t handle);


/**
 * @brief Aerender load template.
 * @param handle    Aerender handle.
 * @param path      Template path.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_load_template(bef_aerender_handle_t handle, const char* path);


/**
 * @brief Aerender load template with file name.
 * @param handle    Aerender handle.
 * @param path      Template path.
 * @param fileName  File name.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_load_template_with_file_name(bef_aerender_handle_t handle, const char* path, const char* fileName);


/**
 * @brief Aerender get template base info.
 * @param frameRate     Aerender handle.
 * @param frameCount    Template path.
 * @param width         width.
 * @param height        height.
 * @return              If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_get_base_info(bef_aerender_handle_t handle, int* frameRate, int* frameCount, int* width, int* height);


/**
 * @brief Aerender seek frame.
 * @param handle    Aerender handle.
 * @param frame     Current frame num.
 * @param output    Output result texture id.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_seek_frame(bef_aerender_handle_t handle, int frame, unsigned int output);


/**
 * @brief Aerender clear data.
 * @param handle    Aerender handle.
 * @return          If succeed return BEF_EFFECT_RESULT_SUC.
 */
BEF_SDK_API bef_effect_result_t bef_effect_aerender_clear_data(bef_aerender_handle_t handle);


#endif /* bef_effect_aerender_api_h */

/**
* @brief Aerender set MSAA mode
* @param handle Aerender handle.
* @param enable If ture, enable MSAA.
* @return        If succeed return BEF_EFFECT_RESULT_SUC.
*/
BEF_SDK_API bef_effect_result_t bef_effect_aerender_set_enable_msaa(bef_aerender_handle_t handle, bool enable);

/**
* @brief Aerender set global config
* @param handle     Aerender handle.
* @param config     Config json string.
* @return           If succeed return BEF_EFFECT_RESULT_SUC.
*/
BEF_SDK_API bef_effect_result_t bef_effect_aerender_set_global_config(bef_aerender_handle_t handle, const char* config);

/**
* @brief Aerender set bg color
* @param handle Aerender handle.
* @param r      bg color red channel.
* @param g      bg color green channel.
* @param b      bg color blue channel.
* @param a      bg color alpha channel.
* @return       If succeed return BEF_EFFECT_RESULT_SUC.
*/
BEF_SDK_API bef_effect_result_t bef_effect_aerender_set_bg_color(bef_aerender_handle_t handle, float r, float g, float b, float a);


/**
* @brief Aerender set font texture size
* @param handle Aerender handle.
* @param size texture pixels size*size.
* @return  If succeed return BEF_EFFECT_RESULT_SUC.
*/
BEF_SDK_API bef_effect_result_t bef_effect_aerender_set_font_texture_size(bef_aerender_handle_t handle, int size);
