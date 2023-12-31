#ifndef __AVGFILTERTRACKER__
#define __AVGFILTERTRACKER__
#include <mobilecv2/core.hpp>
#include <vector>
#include "ImageTransformNewAlign.h"
#include "autovector.h"
namespace smash {

class AvgFilterTracking {
public:
  AvgFilterTracking() : _input_height(0), _input_width(0), is_first_(true) {}

  template<typename DType>
  int init(DType &points,
           int start,
           int end,
           int height,
           int width,
           int escale,
           int num_point_);
  template<typename DType>
  void GetCurrentPostition(
      const DType &measure_points,
      DType &curr_points);

  template<typename DType>
  void GetCurrentPostitionNew(
      const DType &measure_points,
      DType &curr_points);

  void motionless_smooth(
      const std::vector<mobilecv2::Point_<float> > &measure_points,
      std::vector<mobilecv2::Point_<float> > &curr_points,
      int start,
      int end,
      int x);

  void motionless_smooth_v2(
      const std::vector<mobilecv2::Point_<float> > &measure_points,
      std::vector<mobilecv2::Point_<float> > &curr_points,
      int start,
      int end,
      int x);

    // use for eular smooth
  int init_seq(std::vector<float> &inputs,
               int start,
               int end,
               int escale,
               int num_point_);
  void GetCurrentSeq(const std::vector<float> &measure_inputs,
                     std::vector<float> &curr_inputs);

private:
  std::vector<mobilecv2::Point_<float> > last_points_;
  std::vector<mobilecv2::Point_<float> > last_last_points_;
  std::vector<float> m_diff_x, m_diff_y;
  const float diff_history_weight = 0.2;
  const int window_size = 5;           // be in odd
  const int gaussian_kernel_size = 5;  // be in odd
  const float gaussian_sigma = 3;
  int point_num;
  bool is_first_;
  float exp_scale;
  float exp_scale_new;
  std::vector<float> gaussian_kernel;
  int _input_height;
  int _input_width;
  //float last_mean_mouth_x = 0;
  //float last_mean_mouth_y = 0;
  // use for eular smooth
  std::vector<float> last_inputs_;
  std::vector<float> m_diff;
  std::vector<int> m_count_x;
  std::vector<int> m_count_y;
  void init_gaussian_kernel();
};

template<typename DType>
void AvgFilterTracking::GetCurrentPostition(
    const DType &measure_points,
    DType &curr_points) {
    if ((last_points_.size() == 0) || (measure_points.size() == 0)) {
      curr_points = measure_points;
      return;
    }
    // float zero is not exactly zero
    if (fabs(exp_scale - 0.) < 1e-5) {
        curr_points = measure_points;
    } else {
        curr_points.clear();
        // curr_points.resize(point_num);
        std::vector<float> diff_x(point_num), diff_y(point_num);
        for (int i = 0; i < point_num; ++i) {
            diff_x[i] = measure_points[i].x - last_points_[i].x;
            diff_y[i] = measure_points[i].y - last_points_[i].y;
        }
        if (is_first_) {
            m_diff_x = diff_x;
            m_diff_y = diff_y;
            is_first_ = false;
        } else {
            for (int i = 0; i < point_num; ++i) {
                m_diff_x[i] = m_diff_x[i] * diff_history_weight +
                              diff_x[i] * (1 - diff_history_weight);
                m_diff_y[i] = m_diff_y[i] * diff_history_weight +
                              diff_y[i] * (1 - diff_history_weight);
            }
        }

        // get alpha value based on diff
        for (int i = 0; i < point_num; ++i) {
            float alpha_x = exp(-pow(std::abs(m_diff_x[i]) / exp_scale, 0.5));
            float alpha_y = exp(-pow(std::abs(m_diff_y[i]) / exp_scale, 0.5));
            mobilecv2::Point_<float> p;

            p.x = last_points_[i].x * alpha_x +
                  measure_points[i].x  //(show_points_pool.back()[i].x + diff_x[i])
                  * (1 - alpha_x);
            p.y = last_points_[i].y * alpha_y +
                  measure_points[i].y  //(show_points_pool.back()[i].y + diff_y[i])
                  * (1 - alpha_y);
            // curr_points[i] = p;
            curr_points.push_back(p);
        }
    }
    last_last_points_.resize(last_points_.size());
    last_points_.resize(curr_points.size());

    for (int i = 0; i < last_points_.size(); i++) {
        last_last_points_[i] = last_points_[i];
    }

    for (int i = 0; i < curr_points.size(); i++) {
        last_points_[i] = curr_points[i];
    }
}

template<typename DType>
int AvgFilterTracking::init(DType &points,
                            int start,
                            int end,
                            int height,
                            int width,
                            int escale,
                            int point_num_) {
    // init or reset
    this->_input_height = height;
    this->_input_width = width;
    //  init_gaussian_kernel();
    point_num = point_num_;
    exp_scale = escale / 720. * std::min(height, width);
    exp_scale_new = escale;
    last_points_.clear();
    for (int i = start; i < end; i++) {
        last_points_.push_back(points[i]);
    }
    is_first_ = true;
    return 0;
}

template<typename DType>
void AvgFilterTracking::GetCurrentPostitionNew(
    const DType &measure_points,
    DType &curr_points) {
  if ((last_points_.size() == 0) || (measure_points.size() == 0)) {
    curr_points = measure_points;
    return;
  }
    // float zero is not exactly zero
    if (fabs(exp_scale - 0.) < 1e-5) {
        curr_points = measure_points;
    } else {
        curr_points.clear();
        // curr_points.resize(point_num);
        std::vector<float> diff_x(point_num), diff_y(point_num);
        for (int i = 0; i < point_num; ++i) {
            diff_x[i] = measure_points[i].x - last_points_[i].x;
            diff_y[i] = measure_points[i].y - last_points_[i].y;
        }
        if (is_first_) {
            m_diff_x = diff_x;
            m_diff_y = diff_y;
            is_first_ = false;
        } else {
            m_diff_x = diff_x;
            m_diff_y = diff_y;
        }

        // get alpha value based on diff
        for (int i = 0; i < point_num; ++i) {
            float alpha_x = exp(-pow(std::abs(m_diff_x[i]) / exp_scale, 3));
            float alpha_y = exp(-pow(std::abs(m_diff_y[i]) / exp_scale, 3));
            mobilecv2::Point_<float> p;

            p.x = last_points_[i].x * alpha_x +
                  measure_points[i].x  //(show_points_pool.back()[i].x + diff_x[i])
                  * (1 - alpha_x);
            p.y = last_points_[i].y * alpha_y +
                  measure_points[i].y  //(show_points_pool.back()[i].y + diff_y[i])
                  * (1 - alpha_y);
            // curr_points[i] = p;
            curr_points.push_back(p);
        }
    }
    last_last_points_ = last_points_;
    last_points_.resize(curr_points.size());

    for(int i = 0;i<curr_points.size();i++) {
        last_points_[i] = curr_points[i];
    }
}

class AffineFilterTracking {
public:
    AffineFilterTracking() : m_exp_scale_(0.), m_point_num_(0), m_is_first_(true) {}
    int init(const std::vector<mobilecv2::Point_<float> > &points,
             int start,
             int end,
             int escale,
             int num_point_);

    void affine_smooth(const std::vector<mobilecv2::Point_<float> > &measure_points,
                       std::vector<mobilecv2::Point_<float> > &curr_points);

    void set_last_points(const std::vector<mobilecv2::Point_<float> > &last_points_) {
        this->m_last_points_ = last_points_;
    }

private:
    std::vector<mobilecv2::Point_<float> > m_last_points_;
    float m_exp_scale_;
    int m_point_num_;
    bool m_is_first_;
    ImageTransformNewAlign m_align_;
};
}  // namespace smash
#endif
