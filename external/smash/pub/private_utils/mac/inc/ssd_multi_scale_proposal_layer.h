#ifndef _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_H_
#define _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_H_

#include <list>
#include <memory>
#include <vector>
#include <map>
#include "Blob.h"
#include "espresso.h"
#include "internal_smash.h"
#include "predictor.h"
#include "ssd_base.h"
#include "tt_common.h"
#include "tt_log.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(ssd)

using namespace smash::private_utils::predict;

/////////////////
// Proposal class
/////////////////
class Proposal {
 public:
  explicit Proposal();
  virtual ~Proposal(){};
  int Init(std::vector<int>& anchor_base_sizes,
           std::vector<std::vector<float>>& scale_vec,
           std::vector<std::vector<float>>& ratio_vec,
           float prob_thresh);

  /*
   void GetProposal(Blob* score, Blob* bbox, const std::vector<Box>& anchor,
   float prob_thresh, int min_size, int stride,
   int net_input_w, int net_input_h,
   std::vector<Box>& proposals);

   void GetProposal(std::vector<Blob*>& scores, std::vector<Blob* > &bboxs,
   std::vector<int>& min_sizes, std::vector<int> &strides,
   int net_input_w, int net_input_h,
   std::vector<Box>& proposals);
   */

  void GetProposal(std::list<std::vector<TargetCandidate>>& tc_list,
                   std::vector<int>& min_sizes,
                   std::vector<int>& strides,
                   float offset,
                   int net_input_w,
                   int net_input_h,
                   std::vector<Box>& proposals);
  
  void GetProposal(std::vector<TargetCandidate>& tc_vec,
                   int level_idx,
                   int min_size,
                   int stride,
                   float offset,
                   int net_input_w,
                   int net_input_h,
                   std::vector<Box>& proposals);

protected:
  void GetProposal(std::vector<TargetCandidate>& tc_vec,
                   const std::vector<Box>& anchor,
                   float prob_thresh,
                   int min_size,
                   int stride,
                   float offset,
                   int net_input_w,
                   int net_input_h,
                   std::vector<Box>& proposals);

  std::vector<std::vector<Box>> anchor_vec_;
  int nms_pre_topn_;
  int nms_post_topn_;
  int nms_thresh_;
  float prob_thresh_;
};

////////////////////
// SSDDetector class
////////////////////
class MultiScaleProposalLayer {
 public:
  explicit MultiScaleProposalLayer();
  virtual ~MultiScaleProposalLayer();

  int Init(std::vector<int> anchor_base_sizes,
           std::vector<int> min_sizes,
           std::vector<int> strides,
           std::vector<std::vector<float>> scale_vec,
           std::vector<std::vector<float>> ratio_vec,
           int nms_pre_topn,
           int nms_post_topn,
           float nms_thresh,
           float prob_thresh,
           int bits);

  virtual std::vector<Box> GetProposals(std::vector<ModelOutput*>& bboxs,
                                std::vector<ModelOutput*>& scores,
                                int net_input_w,
                                int net_input_h);

  std::map<int, std::vector<Box>> GetProposalsMultiLabel(std::vector<ModelOutput*>& bboxs,
                                                         std::vector<ModelOutput*>& scores,
                                                         int net_input_w,
                                                         int net_input_h);

protected:
  Proposal* p_proposal_;
  std::vector<int> base_sizes_;
  std::vector<int> min_sizes_;
  std::vector<int> strides_;
  int nms_pre_topn_;
  int nms_post_topn_;
  float nms_thresh_;
  float prob_thresh_;
  int bits_;
};

NAMESPACE_CLOSE(ssd)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_SSD_MULTI_SCALE_PROPOSAL_LAYER_H_
