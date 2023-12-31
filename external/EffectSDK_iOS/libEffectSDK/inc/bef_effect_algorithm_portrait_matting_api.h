//
//  bef_effect_algorithm_portrait_matting_api.h
//  effect_sdk
//
//  Created by yuan on 2020/11/11.
//

#ifndef bef_effect_algorithm_portrait_matting_api_h
#define bef_effect_algorithm_portrait_matting_api_h

#include "bef_effect_public_define.h"

typedef void *bef_Portrait_MattingHandle;

typedef void* bef_Portrait_MattingBlendHandle;

typedef void* SwingRenderHandle;

/*
* @brief recomment config
**/
typedef struct bef_MP_RecommendConfig{
  int OutputMinSideLen;
  int FrashEvery;
  int EdgeMode;
} bef_MP_RecommendConfig;

/*
* @brief SDK参数
* edge_mode:
*    - 0: no boundary
*    - 1: add boundary
*    - 2: add boundary, 2 is different 1 in strategy but the result has no big difference; we can choose any one
* fresh_every:
*    set call times to do force predict，default value is 15
* MP_OutputMinSideLen:
*    return the min side len; default value is 128, it must be multiple of 16
* MP_OutputWidth
*   without set, just for compatibility
* MP_OutputHeight
 *   without set, just for compatibility
* MP_VideoMode:
*    - 0: image mode
*    - 1: video mode
*/
typedef enum {
  bef_MP_EdgeMode = 0,
  bef_MP_FrashEvery = 1,
  bef_MP_OutputMinSideLen = 2,
  bef_MP_OutputWidth = 3,
  bef_MP_OutputHeight = 4,
  bef_MP_VideoMode = 5,
} bef_MP_ParamType;

/*
 * @brief 模型类型枚举
 **/
typedef enum {
  bef_MP_LARGE_MODEL = 0,
  bef_MP_SMALL_MODEL = 1,
  bef_MP_UNREALTIME_MODEL = 2,
  bef_MP_SUBJECT_MODEL = 3,
  bef_MP_VIDEO_MODEL = 4,
  bef_MP_VIDEO_GPU_MODEL = 5,
} bef_MP_ModelType;

/*
 * @brief matting blend type
 **/
typedef enum
{
    bef_MP_NORMAL = 0,
    bef_MP_PREVIEW = 1,
} bef_MP_Blend_Mode;
/*
 * @brief 输入参数结构体
 **/
typedef struct bef_MP_Args{
  bef_ModuleBaseArgs base;   //基本的视频帧相关的数据
  bool need_flip_alpha;  //指定是否需要对结果翻转
} bef_MP_Args;

/*
 * @brief 返回结构体，alpha
 * 空间需要调用方负责分配内存和释放，保证有效的控场大于等于widht*height
 * @note
 * 根据输入的大小，短边固定到MP_OutputMinSideLen参数指定的大小，长边保持长宽比缩放；
 *       如果输入的image_height > image_width: 则
 *                width = MP_OutputMinSideLen,
 *                height =
 * (int)(1.0*MP_OutputMinSideLen/image_width*image_height);
 *                //如果长度不为16的倍数，则取最近的16的倍数
 *                net_input_w = 16*(int(float(net_input_w)/16+0.5f));
 */
typedef struct bef_MP_Ret{
  unsigned char*
      alpha;  // alpha[i, j] 表示第 (i, j) 点的 mask 预测值，值位于[0, 255] 之间
  int width;   // alpha 的宽度
  int height;  // alpha 的高度
} bef_MP_Ret;

/*
 * @brief 返回结构体，
 * 有效alpha外接框
 */
typedef struct bef_MP_Ret_Rect{
    float left;
    float right;
    float top;
    float down;
} bef_MP_Ret_Rect;
#if BEF_EFFECT_AI_LABCV_TOBSDK

#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
BEF_SDK_API bef_effect_result_t
bef_matting_blend_check_license(JNIEnv* env, jobject context, bef_Portrait_MattingBlendHandle handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t
bef_portrait_matting_check_license(JNIEnv* env, jobject context, bef_Portrait_MattingHandle handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t
bef_portrait_matting_check_license_buffer(JNIEnv* env, jobject context, bef_Portrait_MattingHandle handle, const char* license_buffer, int buffer_len);
BEF_SDK_API bef_effect_result_t
bef_matting_blend_check_license_buffer(JNIEnv* env, jobject context, bef_Portrait_MattingBlendHandle handle, const char* license_buffer, int buffer_len);
#else
BEF_SDK_API bef_effect_result_t
bef_matting_blend_check_license(bef_Portrait_MattingBlendHandle handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t
bef_portrait_matting_check_license(bef_Portrait_MattingHandle handle, const char* licensePath);
BEF_SDK_API bef_effect_result_t
bef_portrait_matting_check_license_buffer(bef_Portrait_MattingHandle handle, const char* license_buffer, int buffer_len);
BEF_SDK_API bef_effect_result_t
bef_matting_blend_check_license_buffer(bef_Portrait_MattingBlendHandle handle, const char* license_buffer, int buffer_len);
#endif

#endif
/*
* @brief create portrait Matting handle
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_CreateHandle(bef_Portrait_MattingHandle* out);

/*
* @brief load model from finder
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_Resource_Handle(bef_Portrait_MattingHandle handle, bef_MP_ModelType type,
                                                        bef_resource_finder finder);

/*
* @brief init portrait Matting model
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_InitModel(bef_Portrait_MattingHandle handle, bef_MP_ModelType type, const char* param_path);

/*
* @brief init portrait Matting model from buffer, recommend android used
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_InitModelFromBuf(bef_Portrait_MattingHandle handle, bef_MP_ModelType type, const char* param_buf, unsigned int len);

/*
 * @brief set sdk params
 **/
BEF_SDK_API bef_effect_result_t bef_MP_SetParam(bef_Portrait_MattingHandle handle, bef_MP_ParamType type, int value);

/*
* @brief get sdk params
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_GetParam(bef_Portrait_MattingHandle handle, bef_MP_ParamType type, int* value);

/*
 * @brief 进行抠图操作
 * @note ret 结构图空间需要外部分配
 **/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_DoPortraitMatting(bef_Portrait_MattingHandle handle, bef_MP_Args* arg, bef_MP_Ret* ret);

/*
* @brief 进行抠图操作
* @note ret，ret_box 结构图空间需要外部分配
**/
BEF_SDK_API bef_effect_result_t bef_MP_DoPortraitMattingRect(bef_Portrait_MattingHandle handle, bef_MP_Args* arg, bef_MP_Ret* ret, bef_MP_Ret_Rect* ret_rect);
///*
//* @brief smooth mask for three frame; before, current, after
//**/
//BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_SmoothMask(bef_Portrait_MattingHandle handle, bef_MP_Args* arg_img_pre, bef_MP_Args* arg_mask_pre, bef_MP_Args* arg_img_cur, bef_MP_Ret* arg_mask_cur, bef_MP_Args* arg_img_aft, bef_MP_Args* arg_mask_aft, bef_MP_Ret* ret, bef_MP_Ret_Rect* ret_rect);

/*
 * @brief return alpha width and height
 **/
BEF_SDK_API bef_effect_result_t bef_MP_GetAlphaSize(bef_Portrait_MattingHandle handle, int image_width, int image_height, int *alpha_width, int *alpha_height);

/*
* @brief create blend handle
**/
BEF_SDK_API int bef_Portrait_Matting_CreateBlendHandle(bef_Portrait_MattingBlendHandle* out);


/**
 * @brief create blend handler with gpdevice.
 * 
 * @param engine    [out] matting engine
 * @param gpdevice  [in] gpdevice
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_CreateBlendHandle_with_gpdevice(bef_Portrait_MattingBlendHandle* engine, gpdevice_handle gpdevice);

/**
 * @brief set matting blend mode
 * 
 * @param handle [in]  handle       matting handle
 * @param model [in]  blend_mode    0: normal (set black outside the mask), 1: preview (draw color inside the mask)
 * @return bef_effect_result_t If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h. 
 */
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_Set_Blend_Mode(bef_Portrait_MattingBlendHandle handle, bef_MP_Blend_Mode blend_mode);

/**
 * @brief set preview color inside the mask.
 * 
 * @param handle [in]  handle     matting handle
 * @param preview_color   preview RGBA color, range 0.0~1.0.
 * @return BEF_SDK_API 
 */
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_Set_Blend_Preview_Params(bef_Portrait_MattingBlendHandle handle, float preview_color[4]);

/*
 * @brief mask blend, should be call in render thread
 * @param   [in]  handle       matting handle
 * @param   [in]  input_tex    input gl texture id
 * @param   [out]  output_tex   output gl texture id
 * @param   [in]  tex_width    input/output texture width
 * @param   [in]  tex_height   input/output texture height
 * @param   [in]  mask_tex     mask gl texture id
 * @param   [in]  mask_width   mask texture width
 * @param   [in]  mask_height  mask texture height
 * @param   [in]  mask_rect    mask rect return from bef_MP_Ret
 **/
BEF_SDK_API unsigned int bef_Portrait_Matting_Blend(bef_Portrait_MattingBlendHandle handle, unsigned int input_tex, unsigned int output_tex, unsigned int tex_width, unsigned int tex_height, unsigned int mask_tex, unsigned int mask_width, unsigned int mask_height, float mask_rect[4]);

/**
 * @brief render input texture with blending mask texture.
 * @param handle            [in] matting handler
 * @param input_device_tex  [in] input device texture
 * @param output_device_tex [in] output device texture
 * @param tex_width         [in] input/output texture width
 * @param tex_height        [in] input/output texture height
 * @param mask_device_tex   [in] mask device texture
 * @param mask_width        [in] mask texture width
 * @param mask_height       [in] mask texture height
 * @param mask_rect         [in] mask texture rect, return from bef_MP_Ret.
 * @return bef_effect_result_t 
 */
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_Blend_device_texture(bef_Portrait_MattingBlendHandle handle,
                                                                          device_texture_handle input_device_tex,
                                                                          device_texture_handle output_device_tex,
                                                                          unsigned int tex_width,
                                                                          unsigned int tex_height,
                                                                          device_texture_handle mask_device_tex,
                                                                          unsigned int mask_width,
                                                                          unsigned int mask_height,
                                                                          float mask_rect[4]);

///*
//* @brief reserved function
//**/
//BEF_SDK_API bef_effect_result_t bef_MP_DoPortraitMattingIndex(bef_Portrait_MattingHandle handle,
//                         bef_MP_Args* arg,
//                         int index,
//                         bef_MP_Ret* ret, bef_MP_Ret_Rect* ret_rect);
/*
* @brief release handle
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_ReleaseHandle(bef_Portrait_MattingHandle handle);

/*
* @brief release blend handle
**/
BEF_SDK_API bef_effect_result_t bef_Portrait_Matting_ReleaseBlendHandle(bef_Portrait_MattingBlendHandle handle);

/*
 * @brief process mask
 * @note image_width, image_height 目标alpha 宽高
 **/
BEF_SDK_API bef_effect_result_t bef_MP_ProcessBorder(bef_Portrait_MattingBlendHandle handle,
                         bef_MP_Args* arg,
                         int image_width, int image_height,
                         bef_MP_Ret* ret);

/****************************调用swingManager实现抠像描边的Api接口****************************************/

/**
* @brief create blend handle with swingManager
*
* @param width viewer width
* @param height viewer height
* @param resourceFinder resource finder function, used by ALGORITHM to find model
* @param algorithmAsync [DEPRECATED] update algorithm in async. thread, default value is false
*/
BEF_SDK_API int bef_portrait_matting_create_blend_handle(SwingRenderHandle* out,
                                                       unsigned int width,
                                                       unsigned int height,
                                                       bef_resource_finder resourceFinder,
                                                       bool algorithmAsync);
/**
 * @brief create blend handler with swingManager and gpdevice.
 *
 * @param engine    [out] matting engine
 * @param gpdevice  gpdevice
 * @param width viewer width
 * @param height viewer height
 * @param resourceFinder resource finder function, used by ALGORITHM to find model
 * @param algorithmAsync [DEPRECATED] update algorithm in async. thread, default value is false
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_portrait_matting_create_blend_handle_with_gpdevice(
                                        SwingRenderHandle* engine,
                                        gpdevice_handle gpdevice,
                                        unsigned int width,
                                        unsigned int height,
                                        bef_resource_finder resourceFinder,
                                        bool algorithmAsync);

/**
 * @brief set matting blend mode
 *
 * @param handle [in]  handle       matting handle
 * @param model [in]  blend_mode    0: normal (set black outside the mask), 1: preview (draw color inside the mask)
 * @return bef_effect_result_t If succeed return BEF_EFFECT_RESULT_SUC, other value please see bef_effect_define.h.
 */
BEF_SDK_API bef_effect_result_t bef_portrait_matting_set_blend_mode(SwingRenderHandle handle, bef_MP_Blend_Mode blend_mode);

/**
 * @brief set preview color inside the mask.
 *
 * @param handle [in]  handle     matting handle
 * @param preview_color   preview RGBA color, range 0.0~1.0.
 * @return BEF_SDK_API
 */
BEF_SDK_API bef_effect_result_t bef_portrait_matting_set_blend_preview_params(SwingRenderHandle handle, float preview_color[4]);

/**
 * @brief set stroke params
 * @param handle            [in] matting handler
 * @param strokeJsonParams  [in] pointer of json file
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_portrait_matting_set_stroke_params(SwingRenderHandle handle,
                                                                       const char* strokeJsonParams);

/**
 * @brief set stroke time range and current timeStamp
 * @param handle            [in] matting handler
 * @param startTime         [in] start time of video
 * @param endTime           [in] end time of video
 * @param currentTime       [in] current timeStamp
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t
bef_portrait_matting_set_stroke_time_range(SwingRenderHandle handle,
                                 double startTime,
                                 double endTime,
                                 double currentTime);

/*
 * @brief mask blend, should be call in render thread
 * @param   [in]  handle       matting handle
 * @param   [in]  input_tex    input gl texture id
 * @param   [out]  output_tex   output gl texture id
 * @param   [in]  tex_width    input/output texture width
 * @param   [in]  tex_height   input/output texture height
 * @param   [in]  mask_tex     mask gl texture id
 * @param   [in]  mask_width   mask texture width
 * @param   [in]  mask_height  mask texture height
 * @param   [in]  mask_rect    mask rect return from bef_MP_Ret
 * @param   [in] cpu mask buffer mask_buffer
 **/
BEF_SDK_API unsigned int bef_portrait_matting_blend(SwingRenderHandle handle, unsigned int input_tex, unsigned int output_tex, unsigned int tex_width, unsigned int tex_height, unsigned int mask_tex, unsigned int mask_width, unsigned int mask_height, float mask_rect[4], unsigned char* mask_buffer);

/**
 * @brief render input texture with blending mask texture.
 * @param handle            [in] matting handler
 * @param input_device_tex  [in] input device texture
 * @param output_device_tex [in] output device texture
 * @param tex_width         [in] input/output texture width
 * @param tex_height        [in] input/output texture height
 * @param mask_device_tex   [in] mask device texture
 * @param mask_width        [in] mask texture width
 * @param mask_height       [in] mask texture height
 * @param mask_rect         [in] mask texture rect, return from bef_MP_Ret.
 * @param mask_buffer       [in] cpu mask buffer
 * @return bef_effect_result_t
 */
BEF_SDK_API bef_effect_result_t bef_portrait_matting_blend_device_texture(SwingRenderHandle handle,
                                                                          device_texture_handle input_device_tex,
                                                                          device_texture_handle output_device_tex,
                                                                          unsigned int tex_width,
                                                                          unsigned int tex_height,
                                                                          device_texture_handle mask_device_tex,
                                                                          unsigned int mask_width,
                                                                          unsigned int mask_height,
                                                                          float mask_rect[4],
                                                                          unsigned char* mask_buffer);

/*
* @brief release blend handle
**/
BEF_SDK_API bef_effect_result_t bef_portrait_matting_release_blend_handle(SwingRenderHandle handle);

#endif /* bef_effect_algorithm_portrait_matting_api_h */
