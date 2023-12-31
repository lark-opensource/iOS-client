#ifndef __IMAGETRANSFORMNEWALIGN__
#define __IMAGETRANSFORMNEWALIGN__
#include <mobilecv2/core.hpp>
#include <mobilecv2/imgproc.hpp>
#include <vector>
#include "ImageTransform.h"
#include "autovector.h"

/**    @brief 关键点定位图像及关键点转换相关类
 */
namespace smash {

class ImageTransformNewAlign {
 public:
  ImageTransformNewAlign();

  template<typename DType>
  void setMeanFace(const DType &mean_face) {
    this->mean_face.resize(mean_face.size());
    for(int i = 0; i < mean_face.size(); i++) {
        this->mean_face[i] = mean_face[i];
    }
  }

  template<typename DType>
  void computeTransform(const DType &aligns);

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

  bool checkNeedTransform(const AutoVector<float> &aligns,
                          const int FaceAnchor1,
                          const int FaceAnchor2,
                          const int FaceAnchor3,
                          const int FaceAnchor4,
                          const float threshold = 0.1);

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

  void getAlignAnchor(const AutoVector<float> &aligns,
                      mobilecv2::Vec4f &anchors,
                      const int FaceAnchor1,
                      const int FaceAnchor2,
                      const int FaceAnchor3,
                      const int FaceAnchor4) {
    float x1, y1, x2, y2;
    x1 = (aligns[2 * FaceAnchor1] + aligns[2 * FaceAnchor2]) / 2;
    y1 = (aligns[2 * FaceAnchor1 + 1] + aligns[2 * FaceAnchor2 + 1]) / 2;
    x2 = (aligns[2 * FaceAnchor3] + aligns[2 * FaceAnchor4]) / 2;
    y2 = (aligns[2 * FaceAnchor3 + 1] + aligns[2 * FaceAnchor4 + 1]) / 2;
    anchors = mobilecv2::Vec4f(x1, y1, x2, y2);
  }

 private:
  mobilecv2::Mat tranform_matrix_;
  mobilecv2::Mat tranform_matrix_inv_;
  AutoVector<float> mean_face;
  AutoVector<float> last_aligns;
  bool once_call;
};

template<typename DType>
void ImageTransformNewAlign::computeTransform(
    const DType &aligns) {
  AutoVector<float> src_vec(aligns.size());
  AutoVector<float> dst_vec(mean_face.size());
  float mean_sx = 0, mean_sy = 0, mean_dx = 0, mean_dy = 0;
  for (int i = 0; i < aligns.size() / 2; i++) {
    mean_sx += aligns[2 * i];
    mean_sy += aligns[2 * i + 1];
    mean_dx += mean_face[2 * i];
    mean_dy += mean_face[2 * i + 1];
  }

  mean_sx /= (aligns.size() / 2);
  mean_sy /= (aligns.size() / 2);
  mean_dx /= (aligns.size() / 2);
  mean_dy /= (aligns.size() / 2);

  for (int i = 0; i < aligns.size() / 2; i++) {
    src_vec[2 * i] = aligns[2 * i] - mean_sx;
    src_vec[2 * i + 1] = aligns[2 * i + 1] - mean_sy;
    dst_vec[2 * i] = mean_face[2 * i] - mean_dx;
    dst_vec[2 * i + 1] = mean_face[2 * i + 1] - mean_dy;
  }

  float a = 0, b = 0, norm = 0;
  for (int i = 0; i < aligns.size() / 2; i++) {
    a += src_vec[2 * i] * dst_vec[2 * i] +
         src_vec[2 * i + 1] * dst_vec[2 * i + 1];
    b += src_vec[2 * i] * dst_vec[2 * i + 1] -
         src_vec[2 * i + 1] * dst_vec[2 * i];
    norm += src_vec[2 * i] * src_vec[2 * i] +
            src_vec[2 * i + 1] * src_vec[2 * i + 1];
  }

  a /= norm;
  b /= norm;
  float mean_sx_trans, mean_sy_trans;
  mean_sx_trans = a * mean_sx - b * mean_sy;
  mean_sy_trans = b * mean_sx + a * mean_sy;
  tranform_matrix_.at<float>(0, 0) = a;
  tranform_matrix_.at<float>(0, 1) = -b;
  tranform_matrix_.at<float>(1, 0) = b;
  tranform_matrix_.at<float>(1, 1) = a;
  tranform_matrix_.at<float>(0, 2) = mean_dx - mean_sx_trans;
  tranform_matrix_.at<float>(1, 2) = mean_dy - mean_sy_trans;
  mobilecv2::invertAffineTransform(tranform_matrix_, tranform_matrix_inv_);

  last_aligns.resize(aligns.size());
  for (int i = 0; i < aligns.size(); i++) {
    last_aligns[i] = aligns[i];
  }
  once_call = true;
}

}  // namespace smash
#endif
