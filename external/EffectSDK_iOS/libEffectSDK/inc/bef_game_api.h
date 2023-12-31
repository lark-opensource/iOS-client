#pragma once

#include "bef_game_public_define.h"


// create handle
BEF_GAME_API
bef_game_result_t bef_game_create_handle(bef_game_handle_t* handle);


// init
BEF_GAME_API
bef_game_result_t bef_game_init(bef_game_handle_t handle, int width, int height);


// set sticker
BEF_GAME_API
bef_game_result_t bef_game_set_sticker_path(bef_game_handle_t handle, const char* path);


// set size
BEF_GAME_API
bef_game_result_t bef_game_set_size(bef_game_handle_t handle, int width, int height);


// update
BEF_GAME_API
bef_game_result_t bef_game_process(bef_game_handle_t handle, void *srcTexture, void *dstTexture, double timeStamp);


// pause
BEF_GAME_API
bef_game_result_t bef_game_pause(bef_game_handle_t handle);


// resume
BEF_GAME_API
bef_game_result_t bef_game_resume(bef_game_handle_t handle);


// destory handle
BEF_GAME_API
bef_game_result_t bef_game_destroy_handle(bef_game_handle_t handle);


// message from App to Game
BEF_GAME_API
bef_game_result_t bef_game_process_msg(
    bef_game_handle_t handle, 
    unsigned int msgid,
    long arg1,
    long arg2, 
    const char *arg3);


// message from Game to App
// add message receive function
BEF_GAME_API
bef_game_result_t bef_game_add_msg_receive_func(
    bef_game_handle_t handle,
    bef_game_msg_receive_func pfunc,
    void* userdata);

// remove message receive function
BEF_GAME_API
bef_game_result_t bef_game_remove_msg_receive_func(
    bef_game_handle_t handle,
    bef_game_msg_receive_func pfunc,
    void* userdata);


// touch begin
BEF_GAME_API
bef_game_result_t bef_game_touch_begin(
    bef_game_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[]);


// touch move
BEF_GAME_API
bef_game_result_t bef_game_touch_move(
    bef_game_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[]);


// touch end
BEF_GAME_API
bef_game_result_t bef_game_touch_end(
    bef_game_handle_t handle,
    int num,
    int ids[],
    float xs[],
    float ys[]);
