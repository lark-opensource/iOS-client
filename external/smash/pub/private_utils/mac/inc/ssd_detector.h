#ifndef _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_H_
#define _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_H_

#include <mobilecv2/core.hpp>
#include <string>
#include "espresso.h"
#include "internal_smash.h"
#include "predictor.h"
#include "ssd_base.h"
#include "ssd_multi_scale_proposal_layer.h"
#include "tt_common.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(ssd)

enum SideMode { MaxSide, MinSide };

class Detector {
 public:
  explicit Detector()
          : predictor_(nullptr),
            proposal_layer_(nullptr),
            image_w_(0),
            image_h_(0),
            side_mode_(MinSide) {}

  virtual ~Detector();

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
           SideMode side_mode);

  int InitModel(const std::string& model,
                const char* param,
                int param_len,
                std::vector<std::string>& bbox_pred_layer_names,
                std::vector<std::string>& cls_score_layer_names);

  int SetMaxSideLen(int max_side_len);

  int SetMinSideLen(int min_side_len);

  // Get detection result
  int Detect(mobilecv2::Mat image_bgr,
             std::vector<mobilecv2::Rect_<float>>& objs,
             std::vector<float>& probs);

  int DetectMultiLabel(mobilecv2::Mat image_bgr,
                       std::vector<mobilecv2::Rect_<float>>& objs,
                       std::vector<int>& labels,
                       std::vector<float>& probs);

 protected:
  void MinSideSetting();

  void MaxSideSetting();

  int Inference(mobilecv2::Mat image,
                std::vector<AIRect>& rects,
                std::vector<float>& probs);

  int GetBox(std::vector<AIRect>& rects, std::vector<float>& probs);
  int GetBoxMultiLabel(std::vector<AIRect>& rects, std::vector<int>& labels, std::vector<float>& probs);

  int max_stride_;

  int bits_;

  int side_mode_;
  int max_side_len_;
  int min_side_len_;

  int image_w_;
  int image_h_;

  int net_input_w_;
  int net_input_h_;

  int resize_w_;
  int resize_h_;

  float im_scale_w_;
  float im_scale_h_;

  mobilecv2::Mat net_input_;

  std::vector<std::string> bbox_pred_layer_names_;
  std::vector<std::string> cls_score_layer_names_;

  smash::private_utils::predict::Predictor* predictor_;
  MultiScaleProposalLayer* proposal_layer_;
};

NAMESPACE_CLOSE(ssd)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_SSD_DETECTOR_H_
