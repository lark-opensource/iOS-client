//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef KRYPTON_EFFECT_OUTPUT_STRUCT_H
#define KRYPTON_EFFECT_OUTPUT_STRUCT_H

#include "canvas/base/log.h"
#include "krypton_effect_pfunc.h"

namespace lynx {
namespace canvas {
namespace effect {

#define DEBUG_FACEINFO(faceInfo)                                          \
  KRYPTON_LOGI(" faceInfo:")                                              \
      << "\nid = " << faceInfo->id << "\nscore = " << faceInfo->score     \
      << "\naction = " << faceInfo->action << "\nyaw = " << faceInfo->yaw \
      << "\npitch = " << faceInfo->pitch << "\nroll = " << faceInfo->roll \
      << "\nrect.left = " << faceInfo->rect.left                          \
      << "\nrect.top = " << faceInfo->rect.top                            \
      << "\nrect.right = " << faceInfo->rect.right                        \
      << "\nrect.bottom = " << faceInfo->rect.bottom

// face 106 point results
struct __attribute__((__packed__)) FaceInfo {
  uint32_t face_count;
  struct {
    uint32_t id;
    float score;
    uint32_t action;
    float yaw;
    float pitch;
    float roll;
    uint32_t _padding[6];

    struct {
      uint32_t left, top, right, bottom;
    } rect;
    struct {
      float x, y;
    } points[106];
    uint32_t _padding2[256 - 16 - 212];
  } face[BEF_MAX_FACE_NUM];
};
static_assert(sizeof(FaceInfo) == (4 * 256) * BEF_MAX_FACE_NUM + 4,
              "bad alignment");

// skeleton recognition result
struct __attribute__((__packed__)) SkeletonInfo {
  uint32_t skeleton_count;
  uint32_t orientation;
  struct {
    uint32_t id;
    struct {
      float left, top, right, bottom;
    } rect;
    struct {
      float x, y;
      uint32_t isDetect;
    } points[18];
  } skeleton[5];
};
static_assert(sizeof(SkeletonInfo) == (59 * 4 * 5 + 2 * 4), "bad alignment");

// hand gesture recognition result
struct __attribute__((__packed__)) HandInfo {
  struct KeyPoint {
    float x;  // corresponding to cols, the range is between [0, width]
    float y;  // corresponding to rows, the range is between [0, height]
  };
  enum {
    HAND_MAX_HAND_NUM = 2,
    HAND_KEY_POINT_NUM = 22,
    HAND_KEY_POINT_NUM_EXTENSION = 2
  };

  uint32_t hand_count;
  struct {
    int id;  // id of the hand
    struct {
      int left, top, right, bottom;
    } rect;
    uint32_t action;           // hand action, default: 99
    float rot_angle;           // hand rotation angle, default: 0
    float score;               // hand detection confidence, default: 0
    float rot_angle_bothhand;  // rot angle of both hands, default: 0
    uint32_t seq_action;  // if no sequence action is set to 0, others are valid
                          // values
    KeyPoint key_points[HAND_KEY_POINT_NUM];  // hand key points, default: 0
    KeyPoint
        key_points_extension[HAND_KEY_POINT_NUM_EXTENSION];  // hand key points
                                                             // extension,
                                                             // default: 0
  } p_hands[HAND_MAX_HAND_NUM];
};
static_assert(sizeof(HandInfo) == 58 * 4 * 2 + 4, "bad alignment");

}  // namespace effect
}  // namespace canvas
}  // namespace lynx

#endif /* KRYPTON_EFFECT_OUTPUT_STRUCT_H */
