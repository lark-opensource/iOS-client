#ifndef _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_TORCH_H_
#define _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_TORCH_H_

#include "ssd_detector.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(ssd)

class DetectorTorch : public Detector {
 public:
  explicit DetectorTorch(){}
  virtual ~DetectorTorch(){};


  int Init(std::vector<int> anchor_base_sizes,
                        std::vector<int> min_sizes,
                        std::vector<int> strides,
                        std::vector<std::vector<float>> scale_vec,
                        std::vector<std::vector<float>> ratio_vec,
                        int nms_pre_topn,
                        int nms_post_topn,
                        float nms_thresh,
                        float prob_thresh,
                        int bits,
                        SideMode side_mode,
                        float offset=0.f);
protected:
  int GetBox(std::vector<AIRect>& rects, std::vector<float>& probs);
};

NAMESPACE_CLOSE(ssd)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_TORCH_H_
