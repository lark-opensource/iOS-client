#ifndef _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_PYTORCH_H_
#define _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_PYTORCH_H_

#include "ssd_multi_scale_proposal_layer.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(ssd)

using namespace smash::private_utils::predict;

/////////////////
// Proposal class
/////////////////
class Proposal_pytorch: public Proposal {
 public:
  explicit Proposal_pytorch(){};

  int Init(std::vector<int>& anchor_base_sizes,
           std::vector<int>& base_strides,
           std::vector<std::vector<float>>& scale_vec,
           std::vector<std::vector<float>>& ratio_vec,
           float prob_thresh);
};

////////////////////
// SSDDetector class
////////////////////
class MultiScaleProposalLayerTorch : public MultiScaleProposalLayer{
 public:
  explicit MultiScaleProposalLayerTorch(){};

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
           float offset);

  std::vector<Box> GetProposals(std::vector<ModelOutput*>& bboxs,
                                std::vector<ModelOutput*>& scores,
                                int net_input_w,
                                int net_input_h);
    
private:
    float m_offSet = 0.0f;

};

NAMESPACE_CLOSE(ssd)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_PYTORCH_H_
