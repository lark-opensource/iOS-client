//
// Created by bytedance game on 2018/9/28.
//

#ifndef ANDROIDDEMO_BEF_INFO_STICKER_API_H
#define ANDROIDDEMO_BEF_INFO_STICKER_API_H

#include "bef_effect_public_define.h"
#include "bef_info_sticker_public_define.h"
#include <stdbool.h>

#if BEF_EFFECT_AI_LABCV_TOBSDK
// TOB add auth methods
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
#endif
#endif

//
// Information sticker coordinate system:
//
//                                (0，1)
//       Screen or DrawBoard    ^ Y axis
//      (-1.0, 1.0) ------------|-------------    (1, 1)
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//         (0, -1) |            | origin(0,0)|
//                 |--------------------------> X (1, 0)
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//                 |            |            |
//         (-1,-1) |            |            |    (1,-1)
//                 -------------|-------------
//                               (0, 1)
//
// The coordinates of the information stickers (x, y) are consistent with the OpenGL normalized coordinates
// The corresponding pixel coordinates are determined according to the size of Screen or DrawBoard.
// The screen size is set according to the set_width_height interface.
// e.g.
// screen size is 720 * 1280
// (1.0, 0.5) -> (360.0, 320.0)


//----------------------------------------------------------------------------

/**
 * @brief Create an information sticker handle, which is called by the rendering thread. The old interface uses gles version 2.0 internally. It is recommended to use bef_info_sticker_director_create_with_context.
 * @param outHandlePtr Information sticker handle
 * @param width Canvas width, unit: pixels
 * @param height Canvas height, unit: pixels
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_director_create(bef_info_sticker_director *outHandlePtr,
                                                                 unsigned int width,
                                                                 unsigned int height);

/**
 * @brief Create an information sticker handle
 * @param outHandlePtr Information sticker handle
 * @param width Canvas width, unit: pixels
 * @param height Canvas height, unit: pixels
 * @param type bef_render_api_gles20 uses es2.0, bef_render_api_gles30 uses es3.0
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_director_create_with_context(bef_info_sticker_director *outHandlePtr,
                                                                              unsigned int width,
                                                                              unsigned int height,
                                                                              bef_render_api_type type);

#if BEF_EFFECT_AI_LABCV_TOBSDK
#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
BEF_SDK_API bef_effect_result_t bef_info_sticker_check_license(JNIEnv* env, jobject context, bef_info_sticker_director handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t bef_info_sticker_check_license_buffer(JNIEnv* env, jobject context, bef_info_sticker_director handle, const char* buffer, unsigned long bufferLen);
#else
BEF_SDK_API bef_effect_result_t bef_info_sticker_check_license(bef_info_sticker_director handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t bef_info_sticker_check_license_buffer(bef_info_sticker_director handle, const char* licensePath, unsigned long bufferLen);
#endif
#endif

/**
 * @brief Initialize the information sticker canvas. Called by the rendering thread.
 * @param width  Canvas width, unit: pixels
 * @param height Canvas height, unit: pixels
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_width_height(bef_info_sticker_director handle,
                                                                  unsigned int width,
                                                                  unsigned int height);

/* @brief Create resource finder.
 * @param handle        Information sticker handle
 * @param strModelDir   Model root dir.
 * @return             Function used to find the corresponding model file
*/
BEF_SDK_API bef_resource_finder bef_info_sticker_create_file_resource_finder(bef_info_sticker_director handle, const char *strModelDir);


/** @brief Set function callback pointer, used to find the corresponding model file
 *  @param handle Information sticker handle
 *  @param finder Function callback pointer, used to find the corresponding model file
 * @note If this interface is not called, no algorithm can be enabled.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_resource_finder(bef_info_sticker_director handle, bef_resource_finder finder);


/**
 * @brief Destroy information sticker handle
 * @param handle Information sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_director_destory(bef_info_sticker_director handle);

/**
 * @brief Information sticker timestamp driven interface. Render thread call.
 * @param handle Information sticker handle
 * @param srcTexture Input texture(gles id)
 * @param dstTexture Output texture(gles id)
 * @param timeStamp Unit second
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_process_texture(bef_info_sticker_director handle,
                                                                 bef_InfoSticker_texture *srcTexture,
                                                                 unsigned int dstTexture,
                                                                 double timeStamp);

/**
 * @brief The function is the same as bef_info_sticker_process_texture.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_seek_frame(bef_info_sticker_director handle,
                                                            bef_InfoSticker_texture *srcTexture,
                                                            unsigned int dstTexture,
                                                            double timeStamp);

/**
 * @brief The function is the same as bef_info_sticker_process_texture.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_seek_frame_device_texture(bef_info_sticker_director handle,
                                                            device_texture_handle srcDeviceTexture,
                                                            device_texture_handle dstDeviceTexture,
                                                            double timeStamp);

/**
 * @brief Add sticker, render thread call
 * @param handle Information sticker handle
 * @param stickerPath Resource path
 * @param outStickerName [out] The unique identification name of the sticker
 * @param paramsNum Number of additional parameters
 * @note The following variable parameters are passed in the type const char *
 * Variable participants will be transferred to sticker resource package in order. The parameters are negotiated by the client RD and TA.
 * @note When png is passed in, the variable parameters can be represented by 4 dynamic parameters: left, right, bottom, top.
 * left, right, bottom, top represent the rectangular area of ​​the image displayed on the screen.(Coordinate normalization)
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_dynamic_params(bef_info_sticker_director handle,
                                            const char *stickerPath,
                                            bef_info_sticker_handle *outStickerName,
                                            int paramsNum,
                                            ...);

/**
 * @brief Add stickers, the function is the same as bef_info_sticker_add_sticker_dynamic_params
 * @param handle Information sticker handle
 * @param stickerPath Resource path
 * @param outStickerName [out] The unique identification name of the sticker
 * @param parmsNum Number of additional parameters
 * @note The following variable parameters are passed in the type const char *
 * Variable participants will be transferred to sticker resource package in order. The parameters are negotiated by the client RD and TA.
 * @note When png is passed in, the variable parameters can be represented by 4 dynamic parameters: left, right, bottom, top.
 * left, right, bottom, top represent the rectangular area of ​​the image displayed on the screen.(Coordinate normalization)
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker(bef_info_sticker_director
                             handle, const char *stickerPath,
                             bef_info_sticker_handle *outStickerName,
                             bef_InfoSticker_info *info);

/**
 * @brief Add image stickers, and the description parameters are textureId and normalized AABB bounding box.
 * @param textureWidth  Texture width in pixels
 * @param textureHeight Texture height in pixels
 * @param in_box Normalized coordinates, can describe texture normalized pos, width, height
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_by_textureid_with_box(
                         bef_info_sticker_director handle,
                         unsigned int stickerTextureId,
                         int textureWidth,
                         int textureHeight,
                         bef_BoundingBox_2d in_box,
                         bef_info_sticker_handle *outStickerName);

/**
 * @brief Add image stickers, and the description parameters are textureId and normalized AABB bounding box.
 * @param textureWidth  Texture width in pixels
 * @param textureHeight Texture height in pixels
 * @param in_box Normalized coordinates, can describe texture normalized pos, width, height
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_by_device_texture_with_box(
                         bef_info_sticker_director handle,
                         device_texture_handle stickerDeviceTexture,
                         int textureWidth,
                         int textureHeight,
                         bef_BoundingBox_2d in_box,
                         bef_info_sticker_handle *outStickerName);

/// Deprecated
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_by_textureid(
                                          bef_info_sticker_director handle,
                                          unsigned int stickerTextureId,
                                          int width,
                                          int height,
                                          bef_info_sticker_handle *outStickerName);


/**
 * @brief Add a single graphic sticker, pass rgba buffer, the corresponding sticker is based on the width of the view, and scaled at a resolution of 720P. Called by the rendering thread.
 * @param stickerRgbaBuf Texture data(RGBA)
 * @param textureWidth   Texture width in pixels
 * @param textureHeight  Texture height in pixels
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_by_rgba(
                                     bef_info_sticker_director handle,
                                     const void *stickerRgbaBuf,
                                     int textureWidth,
                                     int textureHeight,
                                     bef_info_sticker_handle *outStickerName);

/**
 * @brief Add a single image sticker(RGBA). The corresponding sticker adapts to the normalized coordinates. Called by the rendering thread.
 * @param textureWidth  Texture width in pixels
 * @param textureHeight Texture height in pixels
 * @param in_box Normalized coordinates, can describe texture normalized pos, width, height
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_sticker_by_rgba_with_box(
                        bef_info_sticker_director handle,
                        const void *stickerRgbaBuf,
                        int textureWidth,
                        int textureHeight,
                        bef_BoundingBox_2d in_box,
                        bef_info_sticker_handle *outStickerName);

/**
 * @brief Remove the sticker and release the CPU and GPU resources corresponding to the sticker. Called by the rendering thread.
 * @param handle Information sticker handle
 * @param stickerName Sticker unique identification name
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_remove_sticker(bef_info_sticker_director handle,
                                                                bef_info_sticker_handle stickerName);


/// Edit environment macro
#define OPERATION_CONTEXT_PREVIEW     "preview"

/// Synthetic environment macro
#define OPERATION_CONTEXT_COMPOSITION "composition"

/**
 * @brief Set the context. Some animations are only displayed in the editing environment.
 * @param handle Information sticker handle
 * @param context OPERATION_CONTEXT_PREVIEW or OPERATION_CONTEXT_COMPOSITION
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_operation_context(bef_info_sticker_director handle, const char * context);

/**
 * @brief Determine whether the sticker is animated. If the sticker contains animation, it will be synthesized according to video
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name.
 * @param isAnimation
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_is_animation(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              bool* isAnimation);

BEF_SDK_API bef_effect_result_t bef_info_sticker_pause_all_animation(bef_info_sticker_director handle, bool pause);

/**
 * @brief Set the rotation angle of the sticker to rotate around the center point of the sticker.
 * @param infoStickerName Sticker unique identification name.
 * @@param angle Sticker rotation angle, angle system. Positive value is counterclockwise, negative value is clockwise.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_rotation(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float angle);
/**
 * @brief Get the rotation angle of the sticker.
 * @param infoStickerName Sticker unique identification name.
 * @param *angle Output angle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_rotation(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float *angle);

/**
 * @brief Set the scale size of the sticker relative to the existing size.Assuming that the current sticker scaleX is 2.0 and the incoming scaleX is 2.0, the actual scaleX is 2.0 * 2.0 = 4.0.
 * @param scaleX X axis scale
 * @param scaleY Y axis scale
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_scale(bef_info_sticker_director handle,
                                                       bef_info_sticker_handle infoStickerName,
                                                       float scaleX,
                                                       float scaleY);

/**
 * @brief Set the absolute scale size of the sticker. Assuming that the current sticker scaleX is 2.0 and the incoming scaleX is 3.0, the actual scaleX is 3.0.
 * @param scaleX X X axis scale
 * @param scaleY Y Y axis scale
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_scale(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           float scaleX,
                                                           float scaleY);
/**
 * @brief Get sticker absolute scale size.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_scale(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           float *x,
                                                           float *y);

/**
 * @brief Set sticker coordinate position, use information sticker normalized coordinates
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param x x axis coordinate, value range [-1.0 ~ 1.0]
 * @param y y axis coordinate, value range [-1.0 ~ 1.0]
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_position(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float x,
                                                              float y);
/**
 * @brief Get sticker coordinate position.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_position(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float *x,
                                                              float *y);

/**
 * @brief Mirror flip sticker, support horizontal or vertical flip.
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param flipX Whether to flip horizontally, true to flip, false to not flip, default false
 * @param flipY Whether to flip vertically, true to flip, false to not flip, default false
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_flip(bef_info_sticker_director handle,
                                                          bef_info_sticker_handle infoStickerName,
                                                          bool flipX,
                                                          bool flipY);

/**
 * @brief Get sticker flip status.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_flip(bef_info_sticker_director handle,
                                                          bef_info_sticker_handle infoStickerName,
                                                          bool *flipX,
                                                          bool *flipY);

/**
 * @brief Set the drawing order of the stickers on the same layer. The smaller the order, the earlier the drawing, order >= 0.
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param order >= 0.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_order_in_layer(bef_info_sticker_director handle,
                                                                    bef_info_sticker_handle infoStickerName,
                                                                    unsigned int order);

/**
 * @brief Get the order in the layer where the sticker is located.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_order_in_layer(bef_info_sticker_director handle,
                                                                    bef_info_sticker_handle infoStickerName,
                                                                    unsigned int *order);

/**
 * @brief Set the sticker to a layer, usually used to group the stickers (such as background and UI grouping), the larger the layer, the higher the layer. layer >= 0.
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param layer  >= 0.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_layer(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           unsigned int layer);

/**
 * @brief Get the sticker layer level.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_layer(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           unsigned int *layer);

/**
 * @brief Set sticker transparency.
 * @infoStickerName Sticker unique identification name
 * @alpha Transparency, [0.0 ~ 1.0], 0 fully transparent, 1 completely opaque
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_alpha(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           float alpha);

/**
 * @brief Get sticker transparency.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_alpha(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           float *alpha);

/**
  * @brief Obtain the display area of ​​the local coordinate system of the sticker. The display area is an AABB bounding box, which is described by bef_BoundingBox_2d. The client uses this area to determine whether the user selected the sticker.
  * @param infoStickerName Sticker unique identification name
  * @param out_box AABB bounding box after the sticker is translated, scaled, and rotated.
  */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_local_boundingbox(bef_info_sticker_director handle,
                                                                       bef_info_sticker_handle infoStickerName,
                                                                       bef_BoundingBox_2d *out_box);

/**
  * @brief Obtain the display area of ​​the local coordinate system of the sticker. The display area is an AABB bounding box, which is described by bef_BoundingBox_2d. The client uses this area to determine whether the user selected the sticker.(The bounding box contains only scaling transformation, not rotation and translation.)
  * @param infoStickerName Sticker unique identification name
  * @param out_box AABB bounding box after the sticker is rotated.
  */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_local_boundingbox_with_scale(bef_info_sticker_director handle,
                                                                                  bef_info_sticker_handle infoStickerName,
                                                                                  bef_BoundingBox_2d *out_box);


/**
 * @brief Get the sticker to display the area in the world coordinate system.

 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_world_boundingbox(bef_info_sticker_director handle,
                                                                       bef_info_sticker_handle infoStickerName,
                                                                       bef_BoundingBox_2d *out_box);

/**
*@brief Get the sticker bounding box real pixel size.
*/
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_local_boundingbox_size(bef_info_sticker_director handle, bef_info_sticker_handle infoStickerName, unsigned int* width, unsigned int* height);

/**
 * @brief Set whether the sticker is hidden. It is different from setting alpha to 0. If it is hidden, OpenGLES drawing will be stopped for the sticker.
 * @param flag true is displayed, false is hidden, and memory is not released when hidden.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_visible(bef_info_sticker_director handle,
                                                             bef_info_sticker_handle infoStickerName,
                                                             bool flag);
/**
 * @brief Whether the sticker is hidden.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_visible(bef_info_sticker_director handle,
                                                             bef_info_sticker_handle infoStickerName,
                                                             bool *flag);

/**
 * @brief Set the time for the sticker to start playing animation(The default is to start playing from 0).
 * @param stickerName Sticker unique identification name
 * @param timeStamp Unit second
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_entrance_time(bef_info_sticker_director handle,
                                                                   bef_info_sticker_handle stickerName,
                                                                   float timeStamp);

// Brush API

BEF_SDK_API bef_effect_result_t  bef_info_begin_2d_brush(bef_info_sticker_director handle);

BEF_SDK_API bef_effect_result_t  bef_info_end_2d_brush(bef_info_sticker_director handle);

BEF_SDK_API bef_effect_result_t  get_info_brush_buf_size(bef_info_sticker_director handle,
                                                         int* bufSize,
                                                         int* width,
                                                         int* height);

BEF_SDK_API bef_effect_result_t  get_info_brush_buf_content(bef_info_sticker_director handle,
                                                            void* pBuf,
                                                            int bufSize);

/**
 @brief Set brush thickness

 @param handle Information sticker handle
 @param size thickness, the normalized value is based on the resolution width.
 @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t  bef_info_set_2d_brush_size(bef_info_sticker_director handle, float size);

// Set brush color
BEF_SDK_API bef_effect_result_t  bef_info_set_2d_brush_color(bef_info_sticker_director handle, float r, float g, float b, float a);

BEF_SDK_API bef_effect_result_t  bef_info_undo_2d_brush_stroke(bef_info_sticker_director handle);

BEF_SDK_API int  bef_info_get_2d_brush_stroke_count(bef_info_sticker_director handle);

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_2d_brush_canvas_alpha(bef_info_sticker_director handle, float alpha);


// new brush api，must use amazing-engine context.

/**
 * @brief add 2d brush sticker
 */

/**
 @brief Add a brush sticker
 @param director Information sticker director handle
 @param brushStickerParams Brush sticker parameters in json format
 @param outStickerName [out] The unique identification name of the sticker
 @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_add_brush_sticker_with_param(bef_info_sticker_director director,
                                                                              const char* brushStickerParams,
                                                                              bef_info_sticker_handle* outStickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_add_brush_sticker_from_draft(bef_info_sticker_director director,
                                                                              const char* dstPath,
                                                                              bef_info_sticker_handle* outStickerName);


/// Deprecated
BEF_SDK_API bef_effect_result_t bef_info_sticker_add_brush_sticker(bef_info_sticker_director director,
                                                                   bef_info_sticker_brush_sticker_info* info,
                                                                   bef_info_sticker_handle* outStickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_begin_brush(bef_info_sticker_director director,
                                                             bef_info_sticker_handle stickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_end_brush(bef_info_sticker_director director);

BEF_SDK_API bef_effect_result_t bef_info_sticker_undo_brush(bef_info_sticker_director director,
                                                            bef_info_sticker_handle stickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_redo_brush(bef_info_sticker_director director,
                                                            bef_info_sticker_handle stickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_clear_brush(bef_info_sticker_director director,
                                                            bef_info_sticker_handle stickerName);

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_brush_resource(bef_info_sticker_director director,
                                                                    const char *path,
                                                                    char **outParams);

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_brush_resource_data(bef_info_sticker_director director,
                                                                    const char *path,
                                                                    const char *resourceId,
                                                                    char **outParams);

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_brush_params(bef_info_sticker_director director,
                                                                  const char* params);

BEF_SDK_API bef_effect_result_t bef_info_sticker_get_brush_state(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    bef_info_sticker_brush_sticker_state* outState,
    bool bboxCalculatedByPixel
);

// fix coordinates of bef_info_sticker_get_brush_state
// old coordinates of bef_info_sticker_get_brush_state
//       Screen or DrawBoard    
//      (-1.0, -1.0) ------------|-------------    (1, -1)
//                 |            |            |
//                 |            |            |
//         (0, -1) |            | origin(0,0)|
//                 |--------------------------> X (1, 0)
//                 |            |            |
//                 |            |            |
//         (-1,-1) |            |            |    (1,1)
//                 -------------|-------------
//       Screen or DrawBoard    v Y axis
//                               (0, 1)
//
// new coordinates of bef_info_sticker_get_brush_state_fix_coord
//       Screen or DrawBoard    ^ Y axis
//      (-1.0, 1.0) ------------|-------------    (1, 1)
//                 |            |            |
//                 |            |            |
//         (0, -1) |            | origin(0,0)|
//                 |--------------------------> X (1, 0)
//                 |            |            |
//                 |            |            |
//         (-1,-1) |            |            |    (1,-1)
//                 -------------|-------------
//                               (0, 1)
//
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_brush_state_fix_coord(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    bef_info_sticker_brush_sticker_state* outState,
    bool bboxCalculatedByPixel
);

BEF_SDK_API bef_effect_result_t bef_info_sticker_get_brush_visible_resource_list(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    char* resourceList
);

BEF_SDK_API bef_effect_result_t bef_info_sticker_get_brush_resource_list(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    char** resourceList,
    bool ignore_erased
);

BEF_SDK_API bef_effect_result_t
bef_info_sticker_release_brush_resource_list(bef_info_sticker_director handle,
    bef_info_sticker_handle sticker_handle,
    char* resourceList);

BEF_SDK_API bef_effect_result_t bef_info_sticker_make_brush_sticker_to_snapshot(bef_info_sticker_director director,
                                                                                bef_info_sticker_handle stickerName,
                                                                                bef_info_sticker_brush_sticker_state* outState);

BEF_SDK_API bef_effect_result_t bef_info_sticker_enable_brush_sticker_auto_mask(bef_info_sticker_director handle, bef_info_sticker_handle stickerName,bool enable);

/**
 * @brief Serialize brush sticker to file. The interface has not yet been implemented.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_serialize_brush_sticker(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName
);

/**
 * @brief Deserialize brush sticker from file. The interface has not yet been implemented.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_deserialize_brush_sticker(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName
);

/**
 * @brief Add a brush stoke which is filled by user's texture
 * @param handle Information sticker handle
 * @param stickerName Sticker unique identification name
 * @param mask Texture for the created stroke
 * @param bbox Bounding box for the created stroke
 * @param flipMode Flip mode to fill from the mask texture to the created stroke, 0: no flip, 1: vertical flip, 2: horizonal flip, 3: flip both
*/
BEF_SDK_API  bef_effect_result_t bef_info_sticker_add_stroke_to_brush_sticker(
    bef_info_sticker_director handle,
    bef_info_sticker_handle stickerName,
    bef_InfoSticker_texture* mask,
    bef_BoundingBox_2d* bbox,
    int flipMode
);

// texture save api, must use amazing-engine context. save brush texture to png file.
/**
 * @param handle      Information sticker handle
 * @param stickerName Sticker unique identification name
 * @param pngPath     png path
 * @param pFunc       call back func
 * @param userData    user data pointer
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_save_texture_to_png(
    bef_info_sticker_director handle,
    bef_info_sticker_handle stickerName,
    const char* pngPath,
    bef_brush2d_save_png_callback pFunc,
    void* userData);

BEF_SDK_API bef_effect_result_t bef_info_sticker_save_brush_to_resource(
    bef_info_sticker_director handle,
    bef_info_sticker_handle stickerName,
    const char* resourcePath,
    bef_brush2d_save_png_callback pFunc,
    void* userData);

/**
 * @param handle      Information sticker handle
 * @param stickerName Sticker unique identification name
 * @param cachePath   brush context local directory, /xxx/xxx/xxx, differ with undo-redo cache directory.
 * @param pFunc       callback when brush context is synchronously saved.
 * @param userData    user defined pointer
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 * @note This api is synchronously executed, make sure it is called in effect render thread.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_save_brushContext_to_cache(
    bef_info_sticker_director handle,
    bef_info_sticker_handle stickerName,
    const char* cachePath,
    bef_save_brushContext_callback pFunc,
    void* userData);
/**
 * @brief Set sticker coordinate position, use information sticker normalized coordinates
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param info Number of additional parameters
 * @note The following variable parameters are passed in the type const char *
 * Variable participants will be transferred to sticker resource package in order. The parameters are negotiated by the client RD and TA.
 * @note When png is passed in, the variable parameters can be represented by 4 dynamic parameters: left, right, bottom, top.
 * left, right, bottom, top represent the rectangular area of ​​the image displayed on the screen.(Coordinate normalization)
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_params(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              bef_InfoSticker_info *info);

/**
 * @param handle      Information sticker handle
 * @param stickerName Sticker unique identification name
 * @param error       state of saveing texture, true is succ, false if fail.
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_texture_saving_state(
    bef_info_sticker_director handle,
    bef_info_sticker_handle stickerName,
    bool* error);

// texture cache api, must use amazing-engine context. Used in history record feature of 2d brush and cutout brush.
/**
 * @param handle      Information sticker handle
 * @param cachePath   texture cache path
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_texture_cache_path(bef_info_sticker_director handle, const char* cachePath);

/**
 * @param handle      Information sticker handle
 * @param maxMemSize  max memory size, uint MB
 * @return            if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_texture_cache_total_mem_size(bef_info_sticker_director handle, unsigned int* totalMemCache);

/**
 * @param handle       Information sticker handle
 * @param maxCacheSize max storage size, uint MB
 * @return             if succeed return BEF_EFFECT_RESULT_SUC,  other value please see bef_effect_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_texture_cache_total_cache_size(bef_info_sticker_director handle, unsigned int* totalCacheSize);

// Vector Graphics api
/**
 * @brief Add a vector graphics information sticker
 * @param director Information sticker handle
 * @param stickerPath Resource file path of the vector graphics sticker
 * @param outStickerName Output vector graphics sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_add_vector_graphics_sticker(
    bef_info_sticker_director director,
    const char* stickerPath,
    bef_info_sticker_handle* outStickerName);

/**
 * @brief Remove a vector graphics information sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_remove_vector_graphics_sticker(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName);

/**
 * @brief Set the resource path of current vector graphics
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_current_vector_graphics_resource(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    const char* path);

/**
 * @brief Set the params for current vector graphics resource
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param params Params info of current vector graphics resource in json format
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_current_vector_graphics_resource_params(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    char* params);

/**
 * @brief Get all vector graphics from the vector graphics sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param graphics Output all graphics in json format
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_vector_graphics_state(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    char** graphics);

/**
 * @brief Remove a geometry from vector graphics sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param geometryID Name of the geometry
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_remove_vector_graphics_geometry(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    const char* geometryID);

/**
 * @brief Get params from a geometry
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param geometryParams Output params of the geometry in json format
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_vector_graphics_geometry_params(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    const char* geometryID,
    char** geometryParams);

/**
 * @brief Set params to a geometry
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param geometryParams  Params to be applied to a geometry in json format
 * @param isMilestone Current seted params to a geometry can be applied undo/redo
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_vector_graphics_geometry_params(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    const char* geometryID,
    const char* geometryParams,
    bool isMilestone);

/**
 * @brief Set brush enable in vector graphics sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 * @param enable enable
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_vector_graphics_brush_enable(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName,
    bool enable);

/**
 * @brief Undo the last operation in vector graphics sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_vector_graphics_undo_brush(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName);

/**
 * @brief Redo the last operation in vector graphics sticker
 * @param director Information sticker handle
 * @param stickerName Vector graphics sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_vector_graphics_redo_brush(
    bef_info_sticker_director director,
    bef_info_sticker_handle stickerName);

// animation
/**
 @brief Set animation information

 @param handle              Information sticker handle
 @param infoStickerName     Information Sticker Name
 @param animId              Animation id
 @param inTime              Animation start time(s)
 @param stillTime           Animation duration(s)
 @param outTime             Animation end time(s)
 @return If succeed return BEF_RESULT_SUC, other value please refer to bef_effect_base_define.h
 */

/**
    Animation id(Integer with decimal length 5, expressed in ABCDE):
    A = 0 : No animation;
    A = 1 : Acyclic animation;
    A = 2 : Cycle animation;

    BC : queue-anim-entering
    DE : queue-anim-leaving
        Animation type: 0  -->  No animation
                        1  -->  alpha
                        2  -->  enlarge
                        3  -->  shrink
                        4  -->  Right shift
                        5  -->  Left shift
                        6  -->  Down shift
                        7  -->  Up shift
                        8  -->  shake
                        9  -->  rotate
                        10 -->  Flashing
                        11 -->  Heartbeat
                        12 -->  Dance

    e.g.
        1.
        animId = 10101  inTime = 1.0f  stillTime = 2.0f  outTime = 1.0f
        Acyclic animation, entering alpha takes 1 second, pause 2s, leaving alpha takes 1 second

        2.
        animId = 20008  inTime = 2.0f  stillTime = 3.0f  outTime = 0.0f
        Cycle animation, shake 2s, pause 3s, shake 2s, pause 3s ...

        3.
        animId = 0  inTime = 0.0f  stillTime = 0.0f  outTime = 0.0f
        No animation

*/

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_anim(
        bef_info_sticker_director handle,
        bef_info_sticker_handle infoStickerName,
        int animId,
        float inTime,
        float stillTime,
        float outTime);

/**
 * @brief Set animation start time
 * @param startTime Animation start time(s)
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_anim_with_start_time(
        bef_info_sticker_director handle,
        bef_info_sticker_handle infoStickerName,
        int animId,
        float inTime,
        float stillTime,
        float outTime,
        float startTime);

/**
  * @brief Set whether the animation is updated in absolute time.
  * @param handle              Information sticker handle
  * @param infoStickerName     Information Sticker Name
  * @param selfUpdate          Use absolute time when selfUpdate = true, false not
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_anim_absolute_update(
        bef_info_sticker_director handle,
        bef_info_sticker_handle infoStickerName,
        bool absoluteUpdate);

/**
 * @brief Set pin  origin time stamp, this api is for LV reusing the  pin results with mapping time
 * @param handle Information sticker handle
 * @param infoStickerName Information Sticker Name
 * @param trackingTime timeStamp for origin tracking, if timeStamp is -1.0 then not use that time , using seekFrame timeStamp
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_pin_time(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                           double timeStamp);

/**
 * @brief Select pin  area operation
 * @param handle Information sticker handle
 * @param param pin Algorithm sleected area parameters
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_pin_selected_area(bef_info_sticker_director handle,
                                                           bef_InfoSticker_pin_selected_area_param *param);

/**
 * @brief Start pin operation
 * @param handle Information sticker handle
 * @param param pin Algorithm parameters
 * @param debugCode Tracking status
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_begin_pin(bef_info_sticker_director handle,
                                                           bef_InfoSticker_pin_param *param,
                                                           int *debugCode);

/**
 * @brief The algorithm handles the texture unique interface, and other interfaces need to converge to this interface. Pin algorithm uses this interface to seek
 * @param handle          Information sticker handle
 * @param srcTextures     Input texture array
 * @param size            The length of srcTextures array
 * @param param           Algorithm parameters
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_algorithm_textures_with_param(bef_info_sticker_director handle,
                                                                               bef_InfoSticker_texture *srcTextures,
                                                                               unsigned int size,
                                                                               bef_InfoSticker_algorithm_param *param);

/**
 * @brief The algorithm handles the texture unique interface, and other interfaces need to converge to this interface. Pin algorithm uses this interface to seek
 * @param handle          Information sticker handle
 * @param srcDeviceTextures     Input texture array
 * @param size            The length of srcTextures array
 * @param param           Algorithm parameters
 * @return If succeed return IES_RESULT_SUC,  other value please see bef_effect_base_define.h
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_algorithm_textures_with_param_device_texture(bef_info_sticker_director handle,
                                                                               bef_InfoSticker_device_texture *srcDeviceTextures,
                                                                               unsigned int size,
                                                                               bef_InfoSticker_algorithm_param *param);

/**
 * @brief End the pin operation
 * @param handle Information sticker handle
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_end_pin(bef_info_sticker_director handle);

/**
 * @brief Cancel the pin on the specified sticker, clear the corresponding algorithm memory data, and the sticker bef_InfoSticker_pin_state state is changed from PINNED to NONE;
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_cancel_pin(bef_info_sticker_director handle,
                                                            bef_info_sticker_handle infoStickerName);

/// pin data recovery mode
typedef enum bef_InfoSticker_pin_restore_mode {
    BEF_INFOSTICKER_PIN_RESTORE_ORIGIN = 0,            // Pin algorithm data is adapted to the original viewSize
    BEF_INFOSTICKER_PIN_RESTORE_NORMALIZED = 1,         // Pin algorithm data is adapted according to normalization
    BEF_INFOSTICKER_PIN_RESTORE_CROP_NORMALIZED = 2,     // Pin algorithm is adapted according to the normalization of cropping
}bef_InfoSticker_pin_restore_mode;

/**
 * @brief Set pin data recovery mode, the default value is BEF_INFOSTICKER_PIN_RESTORE_ORIGIN
 * @param mode BEF_INFOSTICKER_PIN_RESTORE_ORIGIN : Pin coordinates are not affected by canvas size, BEF_INFOSTICKER_PIN_RESTORE_NORMALIZED : Pin coordinates are affected by canvas size.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_pin_restore_mode(bef_info_sticker_director handle,
                                                                      bef_InfoSticker_pin_restore_mode mode);

/**
 * @brief Pass in the saved algorithm data of the pin to the sticker(Used when the draft box is restored).
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param data The algorithm data using protobuf protocol may contain \0 in the middle, do not use string to read and write. The memory is released by the outside
 * @param size The size of data
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_pin_data(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              const void *data,
                                                              int size);

/**
 * @breif Get sticker pin status.
 * @param handle Information sticker handle
 * @param infoStickerNaame Sticker unique identification name
 * @param state Sticker pin status
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_pin_state(bef_info_sticker_director handle,
                                                               bef_info_sticker_handle infoStickerName,
                                                               bef_InfoSticker_pin_state *state);

/**
 * @brief If the video has black borders on top, bottom, left, or right, you need to tell the video related information, such as the content size.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_crop_content_info(bef_info_sticker_director handle,
                                                                       bef_info_sticker_handle infoStickerName,
                                                                       bef_InfoSticker_crop_content_info *info);

/**
 * @brief Obtain the serialized data of the pin algorithm. The client can write the string to a file, and when the draft box is restored, the file can be used to set the algorithm data to sticker.
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param data The algorithm data using protobuf protocol may contain \0 in the middle, do not use string to read and write. The memory is released by the outside
 * @param size The size of data
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_pin_data(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              void **data,
                                                              int *size);


// Lyrics stickers related API

/**
 * @brief Set subtitle text information, json string
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param content json string
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_srt_info(bef_info_sticker_director handle,
                                                  bef_info_sticker_handle infoStickerName,
                                                  const char *content);

/**
 * @brief Set the font file path
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param path Font file path
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_font_path(bef_info_sticker_director handle,
                                                   bef_info_sticker_handle infoStickerName,
                                                   const char *path);

/**
 * @brief Set the font resource package path.
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param dir The path of the resource package where the font file is located
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_font_dir(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              const char *fontDir);


/**
 * @brief Get the font file path.
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param outPath the font file path
 * @param size outPath pre-allocated space size(byte)
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_font_path(bef_info_sticker_director handle,
                                                               bef_info_sticker_handle infoStickerName,
                                                               char *outPath, const int size);

/**
 * @brief Set the absolute timestamp of lyrics, which is called immediately before bef_info_sticker_process_texture.
 * @param handle Information sticker handle
 * @param timestamp Absolute timestamp for lyrics, in seconds
 * @param startTime Start time of the clipped lyrics, in seconds
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_music_timestamp(bef_info_sticker_director handle,
                                                         double timestamp,
                                                         double startTime);

/**
 * @brief Set the absolute timestamp of lyrics, which is called immediately before bef_info_sticker_process_texture
 * @param handle Information sticker handle
 * @param timestamp Absolute timestamp for lyrics, in seconds
 * @param startTime Start time of the clipped lyrics, in seconds
 * @param isValid Whether the current timestamp is valid
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_valid_music_timestamp(bef_info_sticker_director handle,
                                                         double timestamp,
                                                         double startTime,
                                                         bool isValid);

/**
 * @brief  Set lyrics sticker color value
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param color r, g, b, a color value, range [0.0, 1.0]
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_color(bef_info_sticker_director handle,
                                               bef_info_sticker_handle infoStickerName,
                                               bef_InfoSticker_color color);

/**
 * @brief Get lyrics sticker color value.
 * @param handle Information sticker handle
 * @param infoStickerName Lyrics sticker name
 * @param color r, g, b, a color value, range [0.0, 1.0]
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_color(bef_info_sticker_director handle,
                                                           bef_info_sticker_handle infoStickerName,
                                                           bef_InfoSticker_color *color);

/**
 * @brief The setting of the sticker editing state is to solve the problem that the length of the lyrics constantly changes during the process of rotating, scaling, and translating the sticker, and the rotation center point needs to be reset. The interface is called when the user starts the editing operation or ends the editing operation
 * @param state True means the user is editing, false means the user ends editing
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_manipulate_state(bef_info_sticker_director handle,
                                                          bef_info_sticker_handle infoStickerName,
                                                          bool state);


/**
 * @brief Solve the problem of alignment offset.
 * @param handle Information sticker handle
 * @param offsetX Offset X coordinate
 * @param offsetY Offset Y coordinate
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_offset(bef_info_sticker_director handle, bef_info_sticker_handle stickerName, float *offsetX, float *offsetY);



// Amazing Engine new api

BEF_SDK_API bef_effect_result_t bef_info_sticker_director_create_with_context_amazing(
    bef_info_sticker_director *outHandlePtr,
    unsigned int
    width, unsigned int height,
    bef_render_api_type type,
    bool useAmazing);

BEF_SDK_API bef_effect_result_t bef_info_sticker_director_create_with_context_amazing_and_gpdevice(
    bef_info_sticker_director *outHandlePtr,
    unsigned int
    width, unsigned int height,
    bef_render_api_type type,
    bool useAmazing, gpdevice_handle gpdevice);

BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_sticker_time(bef_info_sticker_director handle,
                                  bef_info_sticker_handle sticker_handle,
                                  double start_time,
                                  double end_time);

/**
 * @brief Add a text information sticker
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_text_sticker(bef_info_sticker_director handle, bef_info_sticker_handle *sticker_handle);

/** setting_params json:
{
"info_sticker_default_params":
{
"pos_x":  0, // -1.0 ~ 1.0 Normalized coordinates, default: 0
"pos_y":  0, // -1.0 ~ 1.0 Normalized coordinates, default:0
"scale":  1.0, // >=0, default 1.0
"rotate": 0.0, // Positive value counterclockwise, negative value clockwise, default 0.0
"alpha":  1.0, // 0.0 ~ 1.0, default: 0
"visible": true,  // Is it visible, true or false, default true
"flip_x":  false,  // Whether to flip horizontally, true or false, default false
"flip_y":  false   // Whether to flip vertically, true or false, default false
}
}
*/
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_text_sticker_with_default_setting(bef_info_sticker_director handle,
                                                       bef_info_sticker_handle *sticker_handle,
                                                       const char* setting_params);


/**
 * @brief Add a rich text information sticker
 * @param handle information director handle
 * @param sticker_handle information sticker handle
 * @param pString json string used for info sticker param setting
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_rich_text_sticker(bef_info_sticker_director handle, bef_info_sticker_handle *sticker_handle, const char* pString);

/**
 * @brief set rich text style by command
 * @param handle infomation sticker director handle
 * @param sticker_handle infomation sticker handle for rich text
 * @param inParam struct for rich text param
 * @param isSync s true means force type setting and then can use bef_info_sticker_get_rich_text synchronous get rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_rich_text(bef_info_sticker_director handle, bef_info_sticker_handle sticker_handle, bef_info_sticker_edit_rich_text_param* inParam, bool isSync);

/**
 * @brief get rich text style by command
 * @param handle infomation sticker director handle
 * @param sticker_handle infomation sticker handle for rich text
 * @param inParam struct for rich text param
 * @param outParam struct for rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_rich_text(bef_info_sticker_director handle,
    bef_info_sticker_handle sticker_handle,
    bef_info_sticker_edit_rich_text_param* inParam,
    bef_info_sticker_edit_rich_text_param** outParam);

/**
 * @brief release rich text outParam which provided by bef_info_sticker_get_rich_text
 * @param handle infomation sticker director handle
 * @param sticker_handle infomation sticker handle for rich text
 * @param outParam struct for rich text param
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_release_rich_text_out_param(bef_info_sticker_director handle,
    bef_info_sticker_handle sticker_handle,
    bef_info_sticker_edit_rich_text_param* outParam);

/**
 * @brief Add an emoticon sticker
 * @param utf8code UTF8 encoding corresponding to the expression
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_emoji(bef_info_sticker_director handle, bef_info_sticker_handle *sticker_handle, const char* utf8code);

/**
 * @param json Text style, shape, etc.
 *
 *
 enum class TextAlign
 {
 LEFT = 0,
 CENTER = 1,
 RIGHT = 2,
 UP = 3,
 DOWN = 4
 };
 fontSize: pt
 lineMaxWidth: The maximum width of a line, exceeding the word wrap, greater than 0 means the percentage of the screen width, less than 0 means no limit
 color: rgba, [0, 1]
 outlineWidth: [0, 1]
 boldWidth: [-0.05, 0.05]
 italicDegree: [0, 45]
 underlineWidth: [0.0, 1.0]
 underlineOffset: [0.0, 1.0]
 shadowSmoothing/shadowOffset/outlineWidth/charSpacing/innerPadding/boldWidth/underlineWidth/underlineOffset relative to char height:
 {
 "version" : "1",
 "text": "content",
 "fontSize": 48,
 "alignType": 0,
 "textColor": [1, 0, 0, 1],
 "background": true,
 "backgroundColor": [1, 1, 1, 1],
 "shadow": true,
 "shadowColor": [0, 1, 0, 1],
 "shadowSmoothing": 1.0,
 "shadowOffset": [0.02, -0.02],
 "outline": true,
 "outlineWidth": 0.3,
 "outlineColor": [0, 0, 1, 1],
 "boldWidth": 0.02,
 "italicDegree": 12,
 "underline": true,
 "underlineWidth": 0.04,
 "underlineOffset": 0.15,
 "charSpacing": 0,
 "innerPadding" 0,
 "lineMaxWidth": -1,
 "fontPath": "",
 "fallbackFontPath": "",
 "effectPath": "/path",
 "shapePath": "/path"
 }
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_text_params(bef_info_sticker_director handle, bef_info_sticker_handle sticker_handle, const char* json);

/**@brief set max pages for global text cache. set 0 means disable the global text cache, or set a number >=1 means enable this feature.
 * @param num max pages num
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_global_text_cache_max_pages(bef_info_sticker_director handle, int num);

/**@brief manually clear the global text cache
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_clear_global_text_cache(bef_info_sticker_director handle);

/**@brief set layer width fot XT, to make multiline possible with attribute "lineMaxWidth" of params
 * @param width layer width, text info max pixel width will be width * lineMaxWidth
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_textInfo_layer_width(bef_info_sticker_director handle, bef_info_sticker_handle sticker_handle, unsigned int width);


BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_effect_text_files(bef_info_sticker_director handle, bef_info_sticker_handle sticker_handle, char** json);

/**
* @brief play gif for yikai 
*/
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_effect_gif_files(bef_info_sticker_director handle, bef_info_sticker_handle sticker_handle, const char* inputGifBuffer, long bufferSize, char** json);

/**
 * @brief Rendering thread
 * @param type        Animation Type, 1:entering 2:leaving 3:cycle
 * @param anim_path   Animation path, cancel animation when empty
 * @param duration    Animation duration
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_anim_new(bef_info_sticker_director handle,
                              bef_info_sticker_handle sticker_handle,
                              int type,
                              const char* anim_path,
                              double duration);

/**
 * @brief Rendering thread
 * @param type        Animation Type, 1:entering 2:leaving 3:cycle
 * @param key   Animation key of property
 * @param value    Animation value of property
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_anim_property(bef_info_sticker_director handle,
                                       bef_info_sticker_handle sticker_handle,
                                       int type,
                                       const char* key,
                                       const char* value);

/**
 * @brief Rendering thread
 * @param type        Animation Type, 1:entering 2:leaving 3:cycle
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_anim_duration(bef_info_sticker_director handle,
                                   bef_info_sticker_handle sticker_handle,
                                   int type,
                                   double duration);

/**
 * @brief Rendering thread
 * @param type        Animation Type, 1:entering 2:leaving 3:cycle
 * @param params    json params
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_anim_params(bef_info_sticker_director handle,
                                 bef_info_sticker_handle sticker_handle,
                                 int type,
                                 const char* params);

/**
 * @brief Rendering thread
 * @param mode        Preview mode 0: Cancel preview mode, 1: preview queue-anim-entering 2: queue-anim-leaving, 3: Cycle animation, 4. Whole sticker
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_sticker_preview_mode(bef_info_sticker_director handle,
                                          bef_info_sticker_handle sticker_handle,
                                          int mode);

/**
 * @brief Set the coordinate position of the sticker anchor point, using normalized coordinates. Taking the center point of the sticker as the origin (0, 0), x is positive to the right, y is positive, and the range of x, y is [-1.0, 1.0].
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param x x axis coordinate, value range [-1.0, 1.0]
 * @param y y axis coordinate, value range [-1.0, 1.0]
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_anchor(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float x,
                                                              float y);
/**
 * @brief Get the coordinates of the anchor point.
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_anchor(bef_info_sticker_director handle,
                                                              bef_info_sticker_handle infoStickerName,
                                                              float *x,
                                                              float *y);

/**
 * @brief Set whether to enable the mechanism of not displaying the texture, which is only effective when using the amazing engine.
*/
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_enable_release_texture(bef_info_sticker_director handle, bool enable);

BEF_SDK_API bef_effect_result_t bef_info_sticker_set_resolution_type(bef_info_sticker_director handle, bef_info_sticker_handle stickerName, bef_InfoSticker_resolution_type type);

/* *********** keyframe ********** */

/**
 * @brief Set keyframe (Add if there is no keyframe at the key time, update if it already exists)
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param keyTime Key time in us
 * @param valueJson Keyframe content json (Contains all adjustable properties)
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_key_frame(bef_info_sticker_director handle,
                               bef_info_sticker_handle infoStickerName,
                               int64_t keyTime,
                               const char* valueJson);

/**
 * @brief Remove keyframe at the key time
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param keyTime Key time in us
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_remove_key_frame(bef_info_sticker_director handle,
                                  bef_info_sticker_handle infoStickerName,
                                  int64_t keyTime);

/**
 * @brief Remove all keyframes
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_remove_all_key_frames(bef_info_sticker_director handle,
                                       bef_info_sticker_handle infoStickerName);

/**
 * @brief Get keyframe properties at any time
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name
 * @param keyTime Key time in us
 * @param valueJson [out] Keyframe content json (Contains all adjustable properties).
   If the sticker has no keyframes, (*valueJson) returns 0, otherwise the caller needs to free (*valueJson) after use by bef_info_sticker_free_key_frame_params
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_key_frame_params(bef_info_sticker_director handle,
                                      bef_info_sticker_handle infoStickerName,
                                      int64_t keyTime,
                                      char** valueJson);

/**
 * @brief Free keyframe content json, which get by bef_info_sticker_get_key_frame_params
 * @param valueJson Keyframe content json
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_free_key_frame_params(char** valueJson);

/* *********** keyframe ********** */

/* *********** info sticker template ********** */

/**
 * @brief Add information sticker template
 * @param handle Information sticker handle
 * @param path Template resource file path
 * @param dependResourceParams Depend resource path info in json format
 * @param outTemplateHandle output template handle
 * @note Use bef_info_sticker_remove_sticker to remove the template
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_add_template(bef_info_sticker_director handle,
                              const char* path,
                              const char* dependResourceParams,
                              bef_info_sticker_handle* outTemplateHandle);

/**
 * @brief Set params to template
 * @param handle Information sticker handle
 * @param templateHandle Template handle
 * @param params Params json
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_set_template_params(bef_info_sticker_director handle,
                                     bef_info_sticker_handle templateHandle,
                                     const char* params);

/**
 * @brief Get params from template
 * @param handle Information sticker handle
 * @param templateHandle Template handle
 * @param outParams Out params json string pointer
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_template_params(bef_info_sticker_director handle,
                                     bef_info_sticker_handle templateHandle,
                                     char** outParams);

/**
 * @brief Get params from template
 * @param stickerPath Resource path
 * @param outParams Out params json string pointer
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_get_pre_add_template_params(const char* stickerPath,
                                     char** outParams);

/**
 * @brief Release param buffer
 * @param outParams Out params json string pointer
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_release_params(char** outParams);

/**
 * @brief convert text info in draft to text template
 * @param [in] params text info in draft
 * @param [out] outParams outParams json string pointer
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_convert_text_to_textTemplate(const char* params,
                                             char** outParams);

#if BEF_FEATURE_CONFIG_INFO_STICKER_TEMPLATE_EDITOR
/**
 * @brief Update template, used by template editor
 * @param handle Information sticker handle
 * @param templateHandle Template handle
 * @param path Template content json
 */
BEF_SDK_API bef_effect_result_t
bef_info_sticker_update_template(bef_info_sticker_director handle,
                              bef_info_sticker_handle templateHandle,
                              const char* content);
#endif


/* *********** info sticker text ********** */

/**
* @brief sys font path
*/
BEF_SDK_API  bef_effect_result_t bef_info_sticker_set_sys_fontpaths(char** path, int count);


/**
 * @brief Set VE color space.
 * @param handle effect handle
 * @param colorSpace  CSF_709_LINEAR = 0, CSF_709_NO_LINEAR = 1, CSF_2020_HLG_LINEAR = 2, CSF_2020_HLG_NO_LINEAR = 3,  CSF_2020_PQ_LINEAR = 4, CSF_2020_PQ_NO_LINEAR = 5
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_set_ve_colorspace(bef_info_sticker_director handle, int colorSpace);

/**
 * @brief Get the width and height of the canvas previously set by bef_info_sticker_set_width_height
 * @param handle Information sticker handle
 * @param info  Canvas width and height
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_get_width_height(bef_info_sticker_director handle, bef_InfoSticker_canvas_info* info);

/**
 * @brief Determine whether the sticker contains dynamic effects.
 * @param handle Information sticker handle
 * @param infoStickerName Sticker unique identification name.
 * @param isDynamic
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_is_dynamic(bef_info_sticker_director handle,
                                                            bef_info_sticker_handle infoStickerName,
                                                            bool* isDynamic);


/**
 * @brief Antialiasing scales the resolution of the image buffer.
 * @param handle Information sticker handle
 * @param in_pixel Source image buffer pointer
 * @param in_width Source image width
 * @param in_height Source image height
 * @param out_pixel Destination image buffer pointer
 * @param out_width Destination image width
 * @param out_height Destination image height
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_resize_image_buffer(bef_info_sticker_director handle,
                                                                     uint8_t * in_pixel,
                                                                     unsigned int in_width,
                                                                     unsigned int in_height,
                                                                     uint8_t * out_pixel,
                                                                     unsigned int out_width,
                                                                     unsigned int out_height);
/**
 * @brief called by picture edit app such as XT, should be called after create_handle at once
 * @param handle                    Information sticker handle
 * @param pictureModeEnable         whether enable picture mode
 */
BEF_SDK_API bef_effect_result_t bef_info_sticker_active_xt_algorithm_config(bef_info_sticker_director handle, bool pictureModeEnable);

#endif //ANDROIDDEMO_BEF_INFO_STICKER_API_H
