//
//  bef_view_api.h
//  effect-sdk
//
//  Created by bytedance on 2020/8/23.
//

#ifndef bef_view_api_h
#define bef_view_api_h

#include "bef_view_public_define.h"
#include "bef_effect_public_business_define.h"


// create handle
BEF_VIEW_API
bef_view_result_t bef_view_create_handle_with_scenekey(bef_view_handle_t* handle, BEFViewSceneKey sceneKey);

// resource finder
BEF_VIEW_API
bef_view_result_t bef_view_set_resource_finder(
    bef_view_handle_t handle,
    bef_resource_finder resourceFinder,
    bef_resource_finder_releaser resourceFinderReleaser);

// init
BEF_VIEW_API
bef_view_result_t bef_view_init(bef_view_handle_t handle, int width, int height);

// attach effectManager
BEF_VIEW_API
bef_view_result_t bef_view_attach_effect_handle(bef_view_handle_t handle, bef_effect_handle_t effectHandle);

// set sticker
BEF_VIEW_API
bef_view_result_t bef_view_set_sticker_path(bef_view_handle_t handle, const char* path);

// set size
BEF_VIEW_API
bef_view_result_t bef_view_set_size(bef_view_handle_t handle, int width, int height);

// update
BEF_VIEW_API
bef_view_result_t bef_view_process(bef_view_handle_t handle, void *srcTexture, void *dstTexture, double timeStamp);


// pause
BEF_VIEW_API
bef_view_result_t bef_view_pause(bef_view_handle_t handle);


// resume
BEF_VIEW_API
bef_view_result_t bef_view_resume(bef_view_handle_t handle);


// destory handle
BEF_VIEW_API
bef_view_result_t bef_view_destroy_handle(bef_view_handle_t handle);


// message from App to Game
BEF_VIEW_API
bef_view_result_t bef_view_process_msg(
    bef_view_handle_t handle,
    unsigned int msgid,
    long arg1,
    long arg2,
    const char *arg3);


// message from Game to App
// add message receive function
BEF_VIEW_API
bef_view_result_t bef_view_add_msg_receive_func(
    bef_view_handle_t handle,
    bef_view_msg_receive_func pfunc,
    void* userdata);

// remove message receive function
BEF_VIEW_API
bef_view_result_t bef_view_remove_msg_receive_func(
    bef_view_handle_t handle,
    bef_view_msg_receive_func pfunc,
    void* userdata);


// touch begin
BEF_VIEW_API
bef_view_result_t bef_view_touch_begin(
    bef_view_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[],
    int pointerCount);


// touch move
BEF_VIEW_API
bef_view_result_t bef_view_touch_move(
    bef_view_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[],
    int pointerCount);


// touch end
BEF_VIEW_API
bef_view_result_t bef_view_touch_end(
    bef_view_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[],
    int pointerCount);

// set render cache data
BEF_VIEW_API
bef_view_result_t bef_view_set_render_cache_data(bef_view_handle_t handle, const char* key, const char* data);
// set render cache texture
BEF_VIEW_API
bef_view_result_t bef_view_set_render_cache_texture(bef_view_handle_t handle, const char* key, const char* path);

BEF_VIEW_API
bef_view_result_t bef_view_set_render_cache_texture_with_buffer(bef_view_handle_t handle, const char* key, bef_src_texture* texture);
#endif /* bef_view_api_h */
