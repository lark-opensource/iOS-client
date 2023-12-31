// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_ANIMATION_INTERPOLATOR_INTERPOLATOR_H_
#define ANIMAX_ANIMATION_INTERPOLATOR_INTERPOLATOR_H_

namespace lynx {
namespace animax {

class Interpolator {
 public:
  virtual ~Interpolator() = default;
  virtual float GetInterpolation(float input) = 0;
};

class LinearInterpolator : public Interpolator {
 public:
  static std::unique_ptr<Interpolator> Make() {
    return std::make_unique<LinearInterpolator>();
  }
  ~LinearInterpolator() override = default;
  float GetInterpolation(float input) override {
    if (input <= 0) {
      return 0;
    } else if (input >= 1) {
      return 1;
    }

    return input;
  }
};

class PathInterpolator : public Interpolator {
 public:
  static std::unique_ptr<Interpolator> Make(PointF &cp1, PointF cp2) {
    return std::make_unique<PathInterpolator>(cp1.GetX(), cp1.GetY(),
                                              cp2.GetX(), cp2.GetY());
  }

  PathInterpolator(const float cp1_x, const float cp1_y, const float cp2_x,
                   const float cp2_y) {
    Build(cp1_x, cp1_y, cp2_x, cp2_y);
  }
  ~PathInterpolator() override { Destroy(); }
  float GetInterpolation(float input) override {
    if (input <= 0) {
      return 0;
    } else if (input >= 1) {
      return 1;
    } else if (!IsValid()) {
      // degrade to LinearInterpolator
      return input;
    }
    size_t beg = 0;
    size_t end = n_ - 1;
    while (end - beg > 1) {
      size_t mid = beg + ((end - beg) >> 1);
      if (input < x_[mid]) {
        end = mid;
      } else {
        beg = mid;
      }
    }
    float output =
        y_[beg] + (y_[end] - y_[beg]) * (input - x_[beg]) / (x_[end] - x_[beg]);
    return output;
  }

 private:
  /**
   * Interpolate the point on line based on (p1_x, p1_y) and (p2_x, p2_y).
   * vector from (p1_x, p1_y) to (p_x, p2) is in the same direction with origin
   * vector from (p1_x, p1_y) to (p2_x, p2_y), and the length is equal to origin
   * length multiplied with t.
   * @param p1_x x of begin point.
   * @param p1_y y of begin point.
   * @param p2_x x of end point.
   * @param p2_y y of end point.
   * @param t    multiplier of length.
   * @param p_x  x of computed point.
   * @param p_y  y of computed point.
   */
  void Mix(float p1_x, float p1_y, float p2_x, float p2_y, float t, float &p_x,
           float &p_y) {
    p_x = (1.f - t) * p1_x + t * p2_x;
    p_y = (1.f - t) * p1_y + t * p2_y;
  }
  /**
   * Build cubic Bezier curve.
   * Start point:              (    0,     0)
   * The first control point:  (cp1_x, cp1_y)
   * The second control point: (cp2_x, cp2_y)
   * End point:                (    1,     1)
   * @param cp1_x x of the first control point.
   * @param cp1_y y of the first control point.
   * @param cp2_x x of the second control point.
   * @param cp2_y y of the second control point.
   */
  void Build(const float cp1_x, const float cp1_y, const float cp2_x,
             const float cp2_y) {
    static constexpr float precision = 0.02f;
    n_ = 1.f / precision + 1;
    static_assert(((size_t)(1.f / precision)) * precision == 1.f,
                  "PathInterpolator use wrong precision");
    x_ = std::make_unique<float[]>(n_);
    y_ = std::make_unique<float[]>(n_);
    float t1_x, t1_y, t2_x, t2_y, t3_x, t3_y, progress;
    for (size_t i = 0; i < n_; ++i) {
      progress = precision * i;
      // Step1: compute temporary point between Start point and CP1 to (t1_x,
      // t1_y)
      Mix(0.f, 0.f, cp1_x, cp1_y, progress, t1_x, t1_y);
      // Step2: compute temporary point between CP1 and CP2 to (t2_x, t2_y)
      Mix(cp1_x, cp1_y, cp2_x, cp2_y, progress, t2_x, t2_y);
      // Step3: compute temporary point between points of Step1 and Step2 to
      // (t1_x, t1_y)
      Mix(t1_x, t1_y, t2_x, t2_y, progress, t1_x, t1_y);
      // Step4: compute temporary point between CP2 and End point to (t3_x,
      // t3_y)
      Mix(cp2_x, cp2_y, 1.f, 1.f, progress, t3_x, t3_y);
      // Step5: compute temporary point between points of Step2 and Step4 to
      // (t2_x, t2_y)
      Mix(t2_x, t2_y, t3_x, t3_y, progress, t2_x, t2_y);
      // Step6: compute temporary point between points of Step3 and Step5 to
      // (t2_x, t2_y), this is the point what we want.
      Mix(t1_x, t1_y, t2_x, t2_y, progress, t1_x, t1_y);
      x_[i] = t1_x;
      y_[i] = t1_y;
      if (i > 0 && x_[i] <= x_[i - 1]) {
        // This curve isn't injective, thus the PathInterpolator is invalid
        Destroy();
        break;
      }
    }
  }
  void Destroy() { n_ = 0; }
  bool IsValid() { return !!n_; }
  std::unique_ptr<float[]> x_;
  std::unique_ptr<float[]> y_;
  size_t n_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_ANIMATION_INTERPOLATOR_INTERPOLATOR_H_
