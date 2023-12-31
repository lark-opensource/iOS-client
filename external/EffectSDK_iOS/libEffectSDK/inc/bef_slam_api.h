//
//  bef_slam_api.h
//  effect-sdk
//
//  Created by feiper on 2017/10/9.
//  Copyright © 2017 year youdong. All rights reserved.
//

#ifndef bef_slam_api_h
#define bef_slam_api_h

#include "bef_effect_public_define.h"

#if (defined(__ANDROID__) || defined(TARGET_OS_ANDROID)) && (BEF_EFFECT_ANDROID_WITH_JNI)
#include <jni.h>
#endif

///def byted effect handle
//typedef void *bef_effect_handle_t;
//typedef int bef_effect_result_t;

/**
 * @brief Slam       android and ios interface, deal with touch event
 * @param  handle     Effect handler
 * @param x          coordinate x of display area
 * @param y          coordinate y of display area
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_touchEvent(bef_effect_handle_t handle, float x, float y);

BEF_SDK_API bef_effect_result_t bef_effect_slam_process_panEvent(bef_effect_handle_t handle, float x, float y, float factor);

BEF_SDK_API bef_effect_result_t bef_effect_slam_process_scaleEvent(bef_effect_handle_t handle, float x, float factor);

BEF_SDK_API bef_effect_result_t bef_effect_slam_process_rotationEvent(bef_effect_handle_t handle, float x, float factor);

BEF_SDK_API int bef_effect_slam_get_status(bef_effect_handle_t handle);//INIT 0, TRACKING 1, LOST 2, ERROR -1

BEF_SDK_API int bef_effect_slam_get_plane_detected(bef_effect_handle_t handle);//planeDetected 1,  otherwise 0

BEF_SDK_API bef_effect_result_t bef_effect_slam_process_touchDownEvent(bef_effect_handle_t handle);

BEF_SDK_API bef_effect_result_t bef_effect_slam_process_touchUpEvent(bef_effect_handle_t handle);

#if defined(__ANDROID__) || defined(TARGET_OS_ANDROID)
/**
 * @brief Slam       initialization needs extra parameters.
 * @param handle     Effect Handler
 * @param pixelFormat  pixel format
 * @param is_front     camera position
 * @param deviceOritation  screen oritation
 * @param imuFlag     control the imu using bitwise  , the enum bef_imuinfo_flag defines the type.
 * @param phongParamPath  information file include the phone supported
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_deviceConfig(bef_effect_handle_t handle, unsigned int imuFlag);

/**
 * @brief Slam       android interface, deal with accelerator information
 * @param  handle     Effect handler
 * @param x          factor x of accelerator
 * @param y          factor y of accelerator
 * @param z          factor y of accelerator
 * @param timestamp  the interuption timestamp of accelerator, the unit is nano second
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_ingestAcc(bef_effect_handle_t handle, double ax, double ay, double az, double timestamp);

/**
 * @brief Slam       android interface, deal with gyroscop information
 * @param  handle     Effect handler
 * @param x          factor x of gyroscop
 * @param y          factor y of gyroscop
 * @param z          factor y of gyroscop
 * @param timestamp  the interuption timestamp of gyroscop, the unit is nano second
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_ingestGyr(bef_effect_handle_t handle, double wx, double wy, double wz, double timestamp);

/**
 * @brief Slam       android interface, deal with gravity information
 * @param  handle     Effect handler
 * @param x          factor x of gravity
 * @param y          factor y of gravity
 * @param z          factor y of gravity
 * @param timestamp  the interuption timestamp of gravity, the unit is nano second
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_ingestGra(bef_effect_handle_t handle, double gx, double gy, double gz, double timestamp);

/**
 * @brief Slam       android interface, deal with oritation information
 * @param  handle     Effect handler
 * @param x          factor x of oritation
 * @param y          factor y of oritation
 * @param z          factor y of oritation
 * @param timestamp  the interuption timestamp of oritation, the unit is nano second
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_ingestOri(bef_effect_handle_t handle, double wRb[9], int wRbSize, double timeStamp);
#endif

/**
 * @brief Slam       ios interface, deal with imu information
 * @param  handle     Effect handler
 * @param acc         accelerator information
 * @param gyro        gyroscope information
 * @param wRb         orientation information
 * @param timestamp  the interuption timestamp, the unit is nano second
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_process_imu(bef_effect_handle_t handle, double *acc, int accNum, double* gyro, int gyroNum, double* wRb, int wRbNum, double timeStamp);


/**
 @brief Slam get auxiliary texture key that can be replaced
 @param handle Effect handler
 @param key output for key. The memory should be managed by caller.
 @param max_key_length max length for output key. It will return fail if max length is not enough.
 */
BEF_SDK_API bef_effect_result_t bef_effect_slam_get_auxiliary_texture_keys(bef_effect_handle_t handle, char *keys, int max_key_length, int max_key_count, int *key_count);

#endif /* bef_slam_api_h */
