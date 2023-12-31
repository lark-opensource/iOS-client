#ifndef _SMASH_PRIVATE_UTILS_INC_MM_DETECTOR_H_
#define _SMASH_PRIVATE_UTILS_INC_MM_DETECTOR_H_

#include <mobilecv2/core.hpp>
#include <string>
#include "espresso.h"
#include "internal_smash.h"
#include "predictor.h"
#include "ssd_base.h"
#include "mm_multi_scale_proposal_layer.h"
#include "tt_common.h"

NAMESPACE_OPEN(smash)
NAMESPACE_OPEN(private_utils)
NAMESPACE_OPEN(mmdet)

//////////////////////////////////////////////////////////////////////////
// 本实现为mmdet codebase在移动端的部署
// 文档及demo见 https://bytedance.feishu.cn/docs/doccnvfLAGES7WnxEhhHq20u5nh
//////////////////////////////////////////////////////////////////////////

enum SideMode { MaxSide, MinSide, SquareSide};
enum ModelType {SSD, RetinaNet, FCOS};

class DetectorMmdet {
public:
    explicit DetectorMmdet();
    ~DetectorMmdet();
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
           bool use_centerness);
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
           bool use_centerness, // only take effect in FCOS & GFL, set it as true in FCOS, false in GFL
           std::vector<float> means,
           std::vector<float> stds);
    // init SSD & RetinaNet
    int InitModel(const std::string& model,
                  const char* param,
                  int param_len,
                  std::vector<std::string>& bbox_pred_layer_names,
                  std::vector<std::string>& cls_score_layer_names);
    // init FCOS
    int InitModel(const std::string& model,
                  const char* param,
                  int param_len,
                  std::vector<std::string>& bbox_pred_layer_names,
                  std::vector<std::string>& cls_score_layer_names,
                  std::vector<std::string>& centerness_layer_names);

    int SetMaxSideLen(int max_side_len);
    int SetMinSideLen(int min_side_len);
    int SetSquareSideLen(int sqaure_side_len);

    // Set and Get Mmdet model type
    int SetMmdetModelType(ModelType type);
    int GetMmdetModelType(ModelType& type);

    // Get detection result
    int DetectMultiLabel(mobilecv2::Mat image,
                         std::vector<mobilecv2::Rect_<float>>& objs,
                         std::vector<int>& labels,
                         std::vector<float>& probs);

 protected:
    void MinSideSetting();

    void MaxSideSetting();

    void SquareSideSetting();

    int Inference(mobilecv2::Mat image, std::vector<AIRect>& rects, std::vector<float>& probs);

    int GetBoxMultiLabelMmdet(std::vector<AIRect>& rects, std::vector<int>& labels, std::vector<float>& probs);

    ModelType mmdet_model_type_;

    int max_stride_;

    int bits_;

    int side_mode_;
    int max_side_len_;
    int min_side_len_;
    int square_side_len_;

    int image_w_;
    int image_h_;

    int net_input_w_;
    int net_input_h_;

    int resize_w_;
    int resize_h_;

    float im_scale_w_;
    float im_scale_h_;
    bool use_centerness_; // if true, use standard FCOS, if false, use GFL without centerness
    mobilecv2::Mat net_input_;

    std::vector<std::string> bbox_pred_layer_names_;
    std::vector<std::string> cls_score_layer_names_;
    std::vector<std::string> centerness_layer_names_;  // FCOS only

    smash::private_utils::predict::Predictor* predictor_;
    MultiScaleProposalLayerMmdet* proposal_layer_;
};

NAMESPACE_CLOSE(mmdet)
NAMESPACE_CLOSE(private_utils)
NAMESPACE_CLOSE(smash)

#endif  // _SMASH_PRIVATE_UTILS_INC_MM_DETECTOR_H_
