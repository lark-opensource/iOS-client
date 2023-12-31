//
//  bef_effect_ar_core_define.h
//  effect_sdk
//
//  Created by 吕晴阳 on 2020/8/23.
//

#ifndef bef_effect_ar_core_define_h
#define bef_effect_ar_core_define_h
#include <stdbool.h>

/// Base
typedef enum
{
    BEF_AR_TRACKING_STATE_TRACKING,
    BEF_AR_TRACKING_STATE_PAUSE,
    BEF_AR_TRACKING_STATE_STOPPED,
} bef_ar_tracking_state;

typedef enum
{
    BEF_AR_TRACKABLE_NOT_VALID,
    BEF_AR_TRACKABLE_BASE,
    BEF_AR_TRACKABLE_PLANE,
    BEF_AR_TRACKABLE_POINT,
    BEF_AR_TRACKABLE_AUGMENTED_IMAGE,
    BEF_AR_TRACKABLE_AUGMENTED_FACE,
} bef_ar_trackable_type;

typedef enum
{
    BEF_AR_PLANE_TYPE_HORIZONTAL_DOWNWARD_FACING ,
    BEF_AR_PLANE_TYPE_HORIZONTAL_UPWARD_FACING,
    BEF_AR_PLANE_TYPE_VERTICAL,
} bef_ar_plane_type;

typedef enum
{
    BEF_AR_POINT_ORIENTATION_MODE_ESTIMATED_SURFACE_NORMAL,
    BEF_AR_POINT_ORIENTATION_MODE_INITIALIZED_TO_IDENTITY,
} bef_ar_point_orientation_mode;

typedef enum
{
    BEF_AR_TRACKING_FAILURE_REASON_NONE,
    BEF_AR_TRACKING_FAILURE_REASON_BAD_STATE,
    BEF_AR_TRACKING_FAILURE_REASON_CAMERA_UNAVAILABLE,
    BEF_AR_TRACKING_FAILURE_REASON_EXCESSIVE_MOTION,
    BEF_AR_TRACKING_FAILURE_REASON_INSUFFICIENT_FEATURES,
    BEF_AR_TRACKING_FAILURE_REASON_INSUFFICIENT_LIGHT,
} bef_ar_tracking_failure_reason;

typedef enum
{
    BEF_AR_COORDINATES_2D_IMAGE_NORMALIZED,
    BEF_AR_COORDINATES_2D_IMAGE_PIXELS,
    BEF_AR_COORDINATES_2D_OPENGL_NORMALIZED_DEVICE_COORDINATES,
    BEF_AR_COORDINATES_2D_TEXTURE_NORMALIZED,
    BEF_AR_COORDINATES_2D_TEXTURE_TEXELS,
    BEF_AR_COORDINATES_2D_VIEW,
    BEF_AR_COORDINATES_2D_VIEW_NORMALIZED,
} bef_ar_coordinates_2d_type;

typedef void* bef_ar_ref_type;

typedef void(*bef_ar_release)(bef_ar_ref_type handle); // for reference type, DeleteGlobalRef

typedef bool(*bef_ar_is_ar_core_supported)();

/// Pose v
typedef struct
{
    float rotationQuaternion[4]; // Pose#getRotationQuaternion()
    float translation[3]; // Pose#getTranslation()
} bef_ar_pose;


/// Anchor r
typedef struct
{
    bef_ar_ref_type handle; // NewGlobalRef
    int guid;
    bef_ar_pose pose; // Anchor#getPose()
    bef_ar_tracking_state trackingState; // Anchor#getTrackingState()
    // cloudAnchorId / cloudAnchorState ...
} bef_ar_anchor;

// Anchor methods
typedef void(*bef_ar_anchor_detach)(bef_ar_ref_type handle); // Anchor#detach()

typedef struct
{
    bef_ar_anchor_detach detach;
} bef_ar_anchor_methods;


/// Trackable r
typedef struct
{
    bef_ar_ref_type handle;
    int guid;
    bef_ar_trackable_type type;
    bef_ar_tracking_state trackingState;
} bef_ar_base_trackable;

// Trackable methods
// Trackable#createAnchor(Pose)
typedef void(*bef_ar_trackable_acquire_anchor)(bef_ar_ref_type handle, const bef_ar_pose* pose, bef_ar_anchor* outAnchor);
// Trackable#getAnchors()
typedef void(*bef_ar_trackable_get_anchors)(bef_ar_ref_type handle, bef_ar_anchor* outAnchors, int length, int* outLength);

typedef struct
{
    bef_ar_trackable_acquire_anchor acquireAnchor;
    bef_ar_trackable_get_anchors getAnchors;
} bef_ar_base_trackable_methods;


/// Plane r
typedef struct
{
    bef_ar_base_trackable base;
    bef_ar_pose centerPose;
    float extentX;
    float extentZ;
    bef_ar_plane_type type;
} bef_ar_plane;

// Plane methods
typedef void(*bef_ar_plane_get_polygon)(bef_ar_ref_type handle, float* polygonVertices, int length, int* outLength);
typedef void(*bef_ar_plane_acquire_subsumed_by)(bef_ar_ref_type handle, bef_ar_plane* outPlane);
typedef bool(*bef_ar_plane_is_pose_in_extents)(bef_ar_ref_type handle, const bef_ar_pose* pose);
typedef bool(*bef_ar_plane_is_pose_in_polygon)(bef_ar_ref_type handle, const bef_ar_pose* pose);
typedef void(*bef_ar_as_plane)(const bef_ar_base_trackable* trackable, bef_ar_plane* plane);

typedef struct
{
    bef_ar_plane_get_polygon getPolygon;
    bef_ar_plane_acquire_subsumed_by acquireSubsumedBy;
    bef_ar_plane_is_pose_in_extents isPoseInExtents;
    bef_ar_plane_is_pose_in_polygon isPoseInPolygon;
    bef_ar_as_plane asPlane;
} bef_ar_plane_methods;


/// Point r
typedef struct
{
    bef_ar_base_trackable base;
    bef_ar_point_orientation_mode orientationMode;
    bef_ar_pose pose;
} bef_ar_trackable_point;
typedef void(*bef_ar_as_point)(const bef_ar_base_trackable* trackable, bef_ar_trackable_point* point);

typedef struct
{
    bef_ar_as_point asPoint;
} bef_ar_trackable_point_methods;

/*
/// AugmentedImage r
typedef struct
{
    bef_ar_base_trackable base;
    bef_ar_pose centerPose;
    float extentX;
    float extentZ;
    int index;
    char name[36];
} bef_ar_augmented_image;
typedef void(*bef_ar_as_augmented_image)(const bef_ar_base_trackable* trackable, bef_ar_augmented_image* augmentedImage);

typedef struct
{
    bef_ar_as_augmented_image asAugmentedImage;
} bef_ar_augmented_image_methods;


/// AugmentedFace r
typedef struct
{
    bef_ar_base_trackable base;
    bef_ar_pose centerPose;
    bef_ar_pose foreheadLeftPose;
    bef_ar_pose foreheadRightPose;
    bef_ar_pose noseTipPose;
} bef_ar_augmented_face;

typedef void(*bef_ar_augmented_face_get_mesh_normals)(bef_ar_ref_type handle, float* normals, int length, int* outLength);
typedef void(*bef_ar_augmented_face_get_mesh_texture_coordinates)(bef_ar_ref_type handle, float* textureCoordinates, int length, int* outLength);
typedef void(*bef_ar_augmented_face_get_mesh_triangle_indices)(bef_ar_ref_type handle, short* triangleIndices, int length, int* outLength);
typedef void(*bef_ar_augmented_face_get_mesh_vertices)(bef_ar_ref_type handle, float* vertices, int length, int* outLength);
typedef void(*bef_ar_as_augmented_face)(const bef_ar_base_trackable* trackable, bef_ar_augmented_face* augmentedFace);


typedef struct
{
    bef_ar_augmented_face_get_mesh_normals getMeshNormals;
    bef_ar_augmented_face_get_mesh_texture_coordinates getMeshTextureCoordinates;
    bef_ar_augmented_face_get_mesh_triangle_indices getMeshTriangleIndices;
    bef_ar_augmented_face_get_mesh_vertices getMeshVertices;
    bef_ar_as_augmented_face asAugmentedFace;
} bef_ar_augmented_face_methods;
 */


/// PointCloud
typedef struct
{
    int id;
    float x;
    float y;
    float z;
} bef_ar_point;


/// CameraIntrinsics v
typedef struct
{
    float focalLength[2];
    int imageDimensions[2];
    float principalPoint[2];
} bef_ar_camera_intrinsics;


/// Camera r
typedef struct
{
    bef_ar_ref_type handle;
    bef_ar_pose displayOrientedPose;
    bef_ar_camera_intrinsics imageIntrinsics;
    bef_ar_pose pose;
    bef_ar_camera_intrinsics textureIntrinsics;
    bef_ar_tracking_state state;
    bef_ar_tracking_failure_reason trackingFailureReason;
    float viewMatrix[16];
} bef_ar_camera;
typedef void(*bef_ar_camera_get_projection_matrix)(bef_ar_ref_type handle, float* dest, int offset, float near, float far);

typedef struct
{
    bef_ar_camera_get_projection_matrix getProjectionMatrix;
} bef_ar_camera_methods;


/// LightEstimate v
typedef struct
{
    float colorCorrection[4];
    float pixelIntensity;
} bef_ar_light_estimate;


/// HitResult r
typedef struct
{
    bef_ar_ref_type handle;
    float distance;
    bef_ar_pose hitPose;
} bef_ar_hit_result;
typedef void(*bef_ar_hit_result_acquire_new_anchor)(bef_ar_ref_type handle, bef_ar_anchor* anchor);
typedef void(*bef_ar_hit_result_acquire_trackable)(bef_ar_ref_type handle, bef_ar_base_trackable* trackable);

typedef struct
{
    bef_ar_hit_result_acquire_new_anchor acquireNewAnchor;
    bef_ar_hit_result_acquire_trackable acquireTrackable;
} bef_ar_hit_result_methods;

typedef struct
{
    const unsigned char* data;
    int width;
    int height;
    int pixelStride;
    int rowStride;
    long timestamp;
} bef_ar_image;
typedef bef_ar_image bef_ar_depth_image;

/// Frame r
typedef struct
{
    bef_ar_ref_type handle;
    // depth image
    bef_ar_pose androidSensorPose;
    bef_ar_light_estimate lightEstimate;
    long timestamp;
    bool hasDisplayGeometryChanged;
} bef_ar_frame;
typedef void(*bef_ar_frame_get_point_cloud)(bef_ar_ref_type handle, bef_ar_point* points, int length, int* outLength);
typedef void(*bef_ar_frame_get_camera)(bef_ar_ref_type handle, bef_ar_camera* camera);
typedef void(*bef_ar_frame_get_update_anchors)(bef_ar_ref_type handle, bef_ar_anchor* anchors, int length, int* outLength);
typedef void(*bef_ar_frame_get_update_trackables)(bef_ar_ref_type handle, bef_ar_trackable_type filterType, bef_ar_base_trackable* trackables, int length, int* outLength);
typedef void(*bef_ar_frame_hit_test)(bef_ar_ref_type handle, float xPx, float yPx, bef_ar_hit_result* hitResults, int length, int* outLength);
typedef void(*bef_ar_frame_hit_test_ray)(bef_ar_ref_type handle, float* origin3, float* direction3, bef_ar_hit_result* hitResults, int length, int* outLength);
typedef void(*bef_ar_frame_transform_coordinates_2d)(bef_ar_ref_type handle, bef_ar_coordinates_2d_type inCoordinates, int numOfVertices, float* vertices2d, bef_ar_coordinates_2d_type outCoordinates, float* outVertices2d);
typedef void(*bef_ar_frame_acquire_image)(bef_ar_ref_type handle, bef_ar_image** pImage);
typedef void(*bef_ar_frame_release_image)(bef_ar_image* image);
typedef float(*bef_ar_frame_get_depth_region_confidence)(bef_ar_ref_type handle, float rectX, float rectY, float rectWidth, float rectHeight);
typedef struct
{
    bef_ar_frame_get_point_cloud getPointCloud;
    bef_ar_frame_get_camera getCamera;
    bef_ar_frame_get_update_anchors getUpdateAnchors;
    bef_ar_frame_get_update_trackables getUpdateTrackables;
    bef_ar_frame_hit_test hitTest;
    bef_ar_frame_hit_test_ray hitTestRay;
    bef_ar_frame_transform_coordinates_2d transformCoordinates2D;
    bef_ar_frame_acquire_image acquireDepthImage;
    bef_ar_frame_acquire_image acquireRawDepthImage;
    bef_ar_frame_acquire_image acquireRawDepthConfidenceImage;
    bef_ar_frame_release_image releaseDepthImage;
    bef_ar_frame_get_depth_region_confidence getDepthRegionConfidence;
} bef_ar_frame_methods;



/// Session r
// Session#createAnchor(Pose), Pose -> Anchor
typedef void(*bef_ar_session_acquire_new_anchor)(bef_ar_ref_type handle, const bef_ar_pose* pose, bef_ar_anchor* outAnchor);
// Session#getAllAnchors()
typedef void(*bef_ar_session_get_all_anchors)(bef_ar_ref_type handle, bef_ar_anchor* outAnchors, int length, int* outLength);
typedef void(*bef_ar_session_get_all_trackables)(bef_ar_ref_type handle, bef_ar_trackable_type filterType, bef_ar_base_trackable* trackables, int length, int* outLength);
typedef void(*bef_ar_session_update)(bef_ar_ref_type handle, bef_ar_frame* frame);
typedef void(*bef_ar_session_set_display_geometry)(bef_ar_ref_type handle, int displayRotation, int widthPx, int heightPx);

typedef struct
{
    bef_ar_session_acquire_new_anchor acquireNewAnchor;
    bef_ar_session_get_all_anchors getAllAnchors;
    bef_ar_session_get_all_trackables getAllTrackables;
    bef_ar_session_update update;
    bef_ar_session_set_display_geometry setDisplayGeometry;
} bef_ar_session_methods;


typedef struct
{
    bef_ar_is_ar_core_supported checkAvailabilityMethod;
    bef_ar_release releaseMethod;
    bef_ar_anchor_methods anchorMethods;
    bef_ar_base_trackable_methods baseTrackableMethods;
    bef_ar_plane_methods planeMethods;
    bef_ar_trackable_point_methods trackablePointMethods;
    // bef_ar_augmented_image_methods augmentedImageMethods;
    // bef_ar_augmented_face_methods augmentedFaceMethods;
    bef_ar_camera_methods cameraMethods;
    bef_ar_hit_result_methods hitResultMethods;
    bef_ar_frame_methods frameMethods;
    bef_ar_session_methods sessionMethods;
} bef_ar_methods;


#endif /* bef_effect_ar_core_define_h */