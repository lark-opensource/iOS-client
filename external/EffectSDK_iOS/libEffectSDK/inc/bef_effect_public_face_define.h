//
// Created by lizhiqi on 2018/5/14.
//

#ifndef EFFECT_SDK_BEF_EFFECT_PUBLIC_FACE_DEFINE_H
#define EFFECT_SDK_BEF_EFFECT_PUBLIC_FACE_DEFINE_H

#include "bef_framework_public_geometry_define.h"

#define BEF_MAX_FACE_NUM  10
#define BEF_FACE_FEATURE_DIM 128

#define FACE_EYE_COUNT 22
#define FACE_EYEBROW_COUNT 13
#define FACE_LIPS_COUNT 64
#define FACE_IRIS_COUNT 20
#define FACE_POINT_COUNT 106

// Accurate results for eyes, eyebrows, lips(204 points)
typedef struct bef_face_ext_info_t {
    int eye_count;
    int eyebrow_count;
    int lips_count;
    int iris_count;

    bef_fpoint eye_left[FACE_EYE_COUNT];
    bef_fpoint eye_right[FACE_EYE_COUNT];
    bef_fpoint eyebrow_left[FACE_EYEBROW_COUNT];
    bef_fpoint eyebrow_right[FACE_EYEBROW_COUNT];
    bef_fpoint lips[FACE_LIPS_COUNT];
    bef_fpoint left_iris[FACE_IRIS_COUNT];
    bef_fpoint right_iris[FACE_IRIS_COUNT];
} bef_face_ext_info;


typedef struct bef_face_106_st {
    bef_rect rect;                // face bbox
    float score;                  // confidence
    bef_fpoint points_array[FACE_POINT_COUNT]; // Array of 106 key points of face
    float visibility_array[FACE_POINT_COUNT];  // The visibility of the corresponding point, the point is not blocked 1.0, blocked 0.0
    float yaw;
    float pitch;
    float roll;
    float eye_dist;               // Distance between eyes
    int ID;
    unsigned int action;          // face action, refer to bef_effect_face_detect.h
    unsigned int tracking_cnt;
} bef_face_106, *p_bef_face_106;


typedef struct bef_face_occlusion_info_base {
  float prob;
  int id;
} bef_face_occlusion_info_base, *p_bef_face_occlusion_info_base;

typedef struct bef_face_occlusion_info {
  bef_face_occlusion_info_base base_occ_info[BEF_MAX_FACE_NUM];
  int face_count;
} bef_face_occlusion_info, *p_bef_face_occlusion_info;

typedef struct bef_face_info_st {
    bef_face_106 base_infos[BEF_MAX_FACE_NUM];
    bef_face_ext_info extra_infos[BEF_MAX_FACE_NUM];
    int face_count;
} bef_face_info, *p_bef_face_info;

typedef struct game_face_ext_info_t {
    int eye_count;
    int eyebrow_count;
    int lips_count;
    int iris_count;

    bef_fpoint eye_left[22];
    bef_fpoint eye_right[22];
    bef_fpoint eyebrow_left[13];
    bef_fpoint eyebrow_right[13];
    bef_fpoint lips[64];
    bef_fpoint left_iris[20];
    bef_fpoint right_iris[20];

//    unsigned char* face_mask;  // face_mask
//    int face_mask_size;        // face_mask_size
//    float* warp_mat;          // warp mat data ptr, size 2*3
} game_face_ext_info;


typedef struct game_face_info_st{
    bef_face_106 base_infos[BEF_MAX_FACE_NUM];
    game_face_ext_info extra_infos[BEF_MAX_FACE_NUM];
    int face_count;
}game_face_info;

typedef struct bef_face_image_st {
    bef_face_106 base_info;
    bef_face_ext_info extra_info;
    unsigned int texture_id;          // Screenshots based on face position (forehead portion added, corrected)
    bef_pixel_format pixel_format;  // RGBA
    int image_width;                // Screenshot pixel width
    int image_height;               // Screenshot pixel height
    int image_stride;               // Stride
} bef_face_image_st, *p_bef_face_image_st;

typedef struct bef_photo_face_image_info_st {
    bef_face_image_st image_infos[BEF_MAX_FACE_NUM];
    int face_count;
} bef_photo_face_image_info_st, *p_bef_photo_face_image_info_st;

typedef struct bef_face_filter_range_st {
    float min_value;        // Filter minimum
    float max_value;        // Filter maximum
} bef_face_filter_range_st;

// Results filter
typedef struct bef_face_filter_policy_st {
    bef_face_filter_range_st yaw_range;
    bef_face_filter_range_st roll_range;
    bef_face_filter_range_st pitch_range;
    float min_face_size; // The minimum value of the shortest side of the face
    float max_bounding_out_of_image_ratio; // The maximum proportion of the face cropping point beyond the original image range relative to the face size
    float max_bounding_out_of_image_count; // The maximum proportion of the face cropping point beyond the original image range relative to the face size

} bef_face_filter_policy_st;


typedef struct bef_algorithm_data_st {
    void *face_data;
    void *face3d_mesh_data;
    void *bling_data;
    void *matting_data;
} bef_algorithm_data;
#endif //EFFECT_SDK_BEF_EFFECT_PUBLIC_FACE_DEFINE_H
