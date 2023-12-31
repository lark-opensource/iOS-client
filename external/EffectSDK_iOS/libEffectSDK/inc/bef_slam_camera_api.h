//
//  SLAMCamera.hpp
//  effect-sdk
//
//  Created by Helen on 2018/3/8.
//  Copyright © 2018 year youdong. All rights reserved.
//

#ifndef SLAMCamera_hpp
#define SLAMCamera_hpp

#include <stdio.h>
#include <stdbool.h>
#include "bef_effect_public_define.h"

#define Matrix4dSize 16
#define IdentifierStringLength 50

typedef void* bef_slam_camera_handle_t;

typedef bool(*bef_device_buildin_slam_supported_checker)();
typedef bef_slam_camera_handle_t(*bef_device_buildin_slam_creator)();
typedef void(*bef_destroy_slam_camera_handle)(bef_slam_camera_handle_t handle);

typedef enum {
    BEF_SLAM_CALLBACK_SUCCESS = 0,
    BEF_SLAM_CALLBACK_FAIL = -1
} bef_slam_callback_result;

typedef struct {
    bef_pose pose;
    char identifier[IdentifierStringLength];
} bef_model_anchor;

typedef struct bef_plane {
    float normal[Vector3dSize];
    float offset;
    float extent[Vector3dSize];
    float center[Vector3dSize];
    char identifier[IdentifierStringLength];
} bef_plane;

typedef struct bef_circle_st {
    bool has_ellipse;            // whether current frame has ellipse
    int ellipse_id;              // the id of current ellipse
    float circle_position[3];   // the circle position in world frame
    float circle_normal[3];      // the circle normal in world frame
    float cicle_radius;          // the circle radius in world frame
} bef_circle;

BEF_SDK_API bool is_plane_valid(const bef_plane *plane);
BEF_SDK_API void clean_plane(bef_plane *plane);
BEF_SDK_API void clean_circle(bef_circle *plane);

typedef enum {
    BEF_SLAM_CAMERA_TRACKING_STATE_ERROR = -1,
    BEF_SLAM_CAMERA_TRACKING_STATE_NONE = 0,
    BEF_SLAM_CAMERA_TRACKING_STATE_LIMITED = 1,
    BEF_SLAM_CAMERA_TRACKING_STATE_AVAILABLE = 2,
} bef_slam_camera_state;

typedef enum {
    BEF_AR_CONFIGURATION_TYPE_NONE = 0,
    BEF_AR_CONFIGURATION_TYPE_WORLD_TRACKING = 1,
} bef_ar_configuration_type;

typedef enum {
    BEF_WORLD_ALIGNMENT_GRAVITY = 0,
    BEF_WORLD_ALIGNMENT_GRAVITY_AND_HEADING = 1,
    BEF_WORLD_ALIGNMENT_CAMERA = 2,
} bef_world_alignment;

typedef enum {
    BEF_PLANE_DETECTION_NONE = 0,
    BEF_PLANE_DETECTION_HORIZONTAL = 1 << 0,
    BEF_PLANE_DETECTION_VERTICAL = 1 << 1,
} bef_plane_detection;

typedef struct {
    bef_ar_configuration_type type;
    bef_world_alignment world_alignment;    
    int plane_detection;                    // vaild when type is BEF_AR_CONFIGURATION_TYPE_WORLD_TRACKING
} bef_ar_configuration;

typedef struct bef_slam_info_st {
    bool active;
    int status; // INIT 0, TRACKING 1, LOST 2, ERROR -1
    int plane_detected; // planeDetected 1,  otherwise 0
    bool plane_update;
    bef_AR_effect view_matrix;
    bef_plane plane;
    int plane_type; // not detected -1, estimated 0, exist 1
} bef_slam_info;

typedef bef_slam_camera_state(*bef_slam_camera_state_getter)(bef_slam_camera_handle_t handle);
typedef bef_slam_callback_result(*bef_slam_camera_pose_getter)(bef_slam_camera_handle_t handle, bef_pose *pose);
typedef bef_slam_callback_result(*bef_slam_camera_intrinsics_getter)(bef_slam_camera_handle_t handle, float *fx, float *fy, float *px, float *py);
typedef bef_slam_callback_result(*bef_slam_camera_projection_getter)(bef_slam_camera_handle_t handle, float *projectionMatrix, const int matrixSize);//needs matrixSize == Matrix4dSize for projectionMatrix

typedef bool(*bef_plane_detected_checker)(bef_slam_camera_handle_t handle);
typedef bef_slam_callback_result(*bef_plane_detected_count_getter)(bef_slam_camera_handle_t handle, int *count);
typedef bef_slam_callback_result(*bef_detected_planes_getter)(bef_slam_camera_handle_t handle, bef_plane *planes, int *planesCount, int maxCount);
typedef bef_slam_callback_result(*bef_specified_detected_plane_getter)(bef_slam_camera_handle_t handle, bef_plane *plane, const char *plane_identifier);
typedef bef_slam_callback_result(*bef_hittest_plane_getter)(bef_slam_camera_handle_t handle, bef_plane *plane, bef_pose *local_pose, float hit_point_x, float hit_point_y);

typedef bef_slam_callback_result(*bef_model_anchor_add_or_update_action)(bef_slam_camera_handle_t handle, const bef_model_anchor *anchor);
typedef bef_slam_callback_result(*bef_model_anchor_remove_action)(bef_slam_camera_handle_t handle, const bef_model_anchor *anchor);

typedef bef_slam_callback_result(*bef_slam_camera_configuration_getter)(bef_slam_camera_handle_t handle, bef_ar_configuration *onfiguration);

BEF_SDK_API void bef_buildin_slam_handler_will_release(bef_slam_camera_handle_t handle);
BEF_SDK_API void bef_set_use_buildin_slam_if_possible_switch(bool use_buildin_slam_if_possible);

BEF_SDK_API void bef_slam_camera_update_environment_cube(bef_slam_camera_handle_t handle, const char *environment_name, const unsigned char *images[], const int images_count, const int image_width, const int image_height, const int image_data_length); // The memory is released by the business party

BEF_SDK_API void bef_register_slam_camera_factory_callback(bef_device_buildin_slam_supported_checker checker, bef_device_buildin_slam_creator creator, bef_destroy_slam_camera_handle deallocator);
BEF_SDK_API void bef_register_slam_camera_callback(bef_slam_camera_state_getter state_getter,
                                                          bef_slam_camera_pose_getter pose_getter,
                                                          bef_slam_camera_intrinsics_getter intrinsics_getter,
                                                          bef_slam_camera_projection_getter projection_getter,

                                                          bef_plane_detected_checker plane_detected_checker,
                                                          bef_plane_detected_count_getter plane_detected_count_getter,
                                                          bef_detected_planes_getter plane_detected_getter,
                                                          bef_specified_detected_plane_getter specified_plane_getter,
                                                          bef_hittest_plane_getter hit_test_plane_getter,

                                                          bef_model_anchor_add_or_update_action anchor_add_action,
                                                          bef_model_anchor_remove_action anchor_remove_action,
                                                   
                                                          bef_slam_camera_configuration_getter configuration_getter);

//event callback

typedef enum {
    BEF_3D_OBJECT_RESPONSE_BOX_EVENT_DISTANCE = 0,
    BEF_3D_OBJECT_RESPONSE_BOX_EVENT_ENTER = 1,
    BEF_3D_OBJECT_RESPONSE_BOX_EVENT_EXIT = 2
} bef_3d_object_response_box_event;

typedef bef_slam_callback_result(*bef_ar_on_3d_object_response_box_event)(const char *entityName, bef_3d_object_response_box_event event, float distanceToResponseBox);
BEF_SDK_API void bef_register_on_3d_object_response_box_event_callback(bef_ar_on_3d_object_response_box_event callback);

typedef bef_slam_callback_result(*bef_ar_on_3d_object_modify_operation_event)(const char *entityName, float x, float y);
BEF_SDK_API void bef_register_on_3d_object_modify_operation_event_callback(bef_ar_on_3d_object_modify_operation_event callback);

//entity transform update
typedef bef_slam_callback_result(*bef_ar_entity_transform_updater)(const char *entityName, const bef_pose *transform_descriptor);
BEF_SDK_API void bef_on_slam_entity_transform_update(bef_effect_handle_t effect_handle, const char *entityName, const bef_pose *transform_descriptor);
BEF_SDK_API void bef_register_slam_entity_transform_update_callback(bef_ar_entity_transform_updater updater);

BEF_SDK_API void bef_get_slam_entity_state_binary_data(bef_effect_handle_t effect_handle, unsigned char **binary_data, int *binary_data_length); // The memory is released by the business party
BEF_SDK_API void bef_set_slam_entity_state_binary_data(bef_effect_handle_t effect_handle, const unsigned char *binary_data, const int binary_data_length);

typedef bef_slam_callback_result(*bef_ar_on_new_event_should_send)(const unsigned char *buffer, const int buffer_length);
BEF_SDK_API void bef_register_on_new_event_should_send_callback(bef_ar_on_new_event_should_send callback);
BEF_SDK_API void bef_on_receive_ar_event(bef_effect_handle_t effect_handle, const unsigned char *binary_data, const int binary_data_length);

typedef bef_slam_callback_result(*bef_ar_model_loaded)(bool is_loaded);
BEF_SDK_API void bef_register_on_ar_model_loaded_callback(bef_ar_model_loaded callback);

BEF_SDK_API void bef_ar_set_ambient_light_intensity(bef_effect_handle_t handle, float intensity);
BEF_SDK_API void bef_ar_set_ambient_light_color_temperature(bef_effect_handle_t handle, float color_temperature);

BEF_SDK_API void bef_ar_get_root_entity_name_and_transform(bef_effect_handle_t effect_handle, const char **entityName, bef_pose *pose);
#endif /* SLAMCamera_hpp */
