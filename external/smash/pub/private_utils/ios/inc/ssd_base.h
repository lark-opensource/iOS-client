#ifndef _SMASH_PRIVATE_UTILS_INC_SSD_BASE_H_
#define _SMASH_PRIVATE_UTILS_INC_SSD_BASE_H_

#include <list>
#include <memory>
#include <vector>
#include "internal_smash.h"
#include "tt_common.h"
#include "tt_log.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(ssd)

////////////
// Box class
////////////
class Box {
 public:
  float top_left_x;
  float top_left_y;
  float bottom_right_x;
  float bottom_right_y;
  float prob;

  explicit Box(float top_left_x,
               float top_left_y,
               float bottom_right_x,
               float bottom_right_y,
               float prob = 0)
      : top_left_x(top_left_x),
        top_left_y(top_left_y),
        bottom_right_x(bottom_right_x),
        bottom_right_y(bottom_right_y),
        prob(prob) {}

  explicit Box() {}

  bool operator<(const Box& other) const { return prob > other.prob; }
};

class TargetCandidate {
 public:
  float d_center_x;
  float d_center_y;
  float d_log_w;
  float d_log_h;
  float prob;
  int w;
  int h;
  int anchor_id;

  explicit TargetCandidate() {}
};

///////////////
// Archor class
///////////////
class Anchor {
 public:
  static int GenerateAnchors(int base_size,
                             const std::vector<float>& scale_vec,
                             const std::vector<float>& ratio_vec,
                             std::vector<Box>& anchors);
    
    // overloading for pytorch ssd
    static int GenerateAnchors_pytorch(int base_size,
                                       int base_stride,
                                       const std::vector<float>& scale_vec,
                                       const std::vector<float>& ratio_vec,
                                       std::vector<Box>& anchors);
};

/////////////////////
// DetectHelper class
/////////////////////
class DetectHelper {
 public:
  // A -> 4 elements, (top_left_x,  top_left_y, bottom_right_x, bottom_right_y)
  static float IoU(float* A, float* B);
  static void NMS(std::vector<Box>& proposals,
                  int nms_pre_topn,
                  int nms_post_topn,
                  float nms_thresh);
};

NAMESPACE_CLOSE(ssd)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_SSD_BASE_H_
