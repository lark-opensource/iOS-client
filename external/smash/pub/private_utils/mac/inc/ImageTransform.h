#ifndef __IMAGETRANSFORM__
#define __IMAGETRANSFORM__
#include <mobilecv2/core.hpp>
#include <vector>
#include "ImageTransform.h"

/**    @brief 关键点定位图像及关键点转换相关类
 */
namespace smash {

class ImageTransform {
 public:
  ImageTransform();

  // set the two points which is used in training as canonical anchors
  //***************************************************************************************
  //
  //! \brief  设置warp图像的anchor点
  //!
  //! \param  [in] vec warp图像的anchor点
  //
  //***************************************************************************************
  void setCanonicalAnchors(const mobilecv2::Vec4f &vec);
  // set the two points in new images which will be aligned to the the canonical
  // anchors

  //***************************************************************************************
  //
  //! \brief
  //! 每一帧结束后，为下一帧设置上一帧的anchor点（用于判断是否需要更新affine矩阵）
  //!
  //! \param  [in] vec 上一帧图像的anchor点
  //
  //***************************************************************************************
  inline void setLastAlignAnchors(const mobilecv2::Vec4f &vec) {
    last_align_anchors_ = vec;
  }

  //***************************************************************************************
  //
  //! \brief  从原图中根据affine矩阵抠图
  //!
  //! \param  [in] image 原图
  //! \param  [out] warp_image warp出来的人脸图
  //! \param  [in] normal_size warp出的图的size
  //
  //***************************************************************************************
  void warpImage(const mobilecv2::Mat &image,
                 mobilecv2::Mat &warp_image,
                 const mobilecv2::Size &normal_size);

  //***************************************************************************************
  //
  //! \brief  将warp图中得到的关键点坐标映射回原图中的关键点坐标
  //!
  //! \param  [in] src warp图中的坐标
  //! \param  [out] dst 原图中的坐标
  //
  //***************************************************************************************
  void tranformPoints2OriginalImage(const mobilecv2::Mat &src,
                                    mobilecv2::Mat &dst);
  //***************************************************************************************
  //
  //! \brief  将原图中得到的关键点坐标映射到warp图中的关键点坐标
  //!
  //! \param  [in] src 原图中的坐标
  //! \param  [out] dst warp图中的坐标
  //
  //***************************************************************************************
  void tranformPoints2WarpedImage(const mobilecv2::Mat &src,
                                  mobilecv2::Mat &dst);

  // estimate affine transfrom [scale, rotation, transformation]
  //***************************************************************************************
  //
  //! \brief  计算warp affine矩阵（跟踪后调用）
  //!
  //! \param  [in] vec anchor点（一般设为眼中心和嘴中心）
  //
  //***************************************************************************************
  void computeTransformForRotation(const mobilecv2::Vec4f &vec);
  //! \brief  更新warp affine逆变换矩阵
  void updateTransformInvForRotation();
  // estimate affine transform [scale_x, scale_y, transformation]
  //***************************************************************************************
  //
  //! \brief  计算warp affine矩阵（检测后调用）
  //!
  //! \param  [in] vec anchor点（一般设为检测框的两个角点）
  //
  //***************************************************************************************
  void computeTransformForResize(const mobilecv2::Vec4f &vec);

  //! \brief  判断是否需要更新warp affine矩阵
  bool checkNeedTransform(const mobilecv2::Vec4f &vec);

  inline mobilecv2::Mat getTranformMatrix2WarpedImage() {
    return tranform_matrix_.clone();
  }
  inline mobilecv2::Mat getTranformMatrix2OriginalImage() {
    return tranform_matrix_inv_.clone();
  }
  inline void setTranformMatrix2WarpedImage(const mobilecv2::Mat &m) {
    m.copyTo(tranform_matrix_);
  }
  inline void setTranformMatrix2OriginalImage(const mobilecv2::Mat &m) {
    m.copyTo(tranform_matrix_inv_);
  }

 private:
  mobilecv2::Mat tranform_matrix_;
  mobilecv2::Mat tranform_matrix_inv_;
  mobilecv2::Mat canonical_anchors_;
  mobilecv2::Mat align_anchors_;
  mobilecv2::Mat X_;  // data to be transformed
  mobilecv2::Vec4f last_align_anchors_;

  void updateXForRotation(const mobilecv2::Vec4f &vec);
  void updateXForResize(const mobilecv2::Vec4f &vec);
};
}  // namespace smash
#endif
