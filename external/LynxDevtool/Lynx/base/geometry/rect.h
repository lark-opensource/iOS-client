#ifndef LYNX_BASE_GEOMETRY_RECT_H_
#define LYNX_BASE_GEOMETRY_RECT_H_

#include <algorithm>

#include "base/geometry/point.h"
#include "base/geometry/size.h"

namespace lynx {
namespace base {
namespace geometry {

template <typename T>
class Rectangle {
 public:
  Rectangle() {}

  Rectangle(const Point<T>& location, const Size<T>& size)
      : location_(location), size_(size) {}

  Point<T> GetLocation() const { return location_; }
  Size<T> GetSize() const { return size_; }

  void SetLocation(const Point<T>& location) { location_ = location; }
  void SetSize(const base::geometry::Size<T>& size) { size_ = size; }
  T X() const { return location_.X(); }
  T Y() const { return location_.Y(); }
  T MaxX() const { return X() + Width(); }
  T MaxY() const { return Y() + Height(); }
  T Width() const { return size_.Width(); }
  T Height() const { return size_.Height(); }

  void SetX(T x) { location_.SetX(x); }
  void SetY(T y) { location_.SetY(y); }
  void SetWidth(T width) { size_.SetWidth(width); }
  void SetHeight(T height) { size_.SetHeight(height); }

  bool IsEmpty() const { return size_.IsEmpty(); }

  void Move(const Point<T>& offset) { location_ += offset; }
  void Move(T dx, T dy) { location_.Move(dx, dy); }

  void Expand(const Size<T>& size) { size_ += size; }
  void Expand(T dw, T dh) { size_.Expand(dw, dh); }
  void Contract(const Size<T>& size) { size_ -= size; }
  void Contract(T dw, T dh) { size_.Expand(-dw, -dh); }

  bool IsIntersectedWith(const Rectangle<T>& other) const {
    return !IsEmpty() && !other.IsEmpty() && X() < other.MaxX() &&
           other.X() < MaxX() && Y() < other.MaxY() && other.Y() < MaxY();
  }

  void Intersect(const Rectangle<T>& other) {
    T left = std::max(X(), other.X());
    T top = std::max(Y(), other.Y());
    T right = std::min(MaxX(), other.MaxX());
    T bottom = std::min(MaxY(), other.MaxY());

    // Return a clean empty rectangle for non-intersecting cases.
    if (left >= right || top >= bottom) {
      left = 0;
      top = 0;
      right = 0;
      bottom = 0;
    }

    location_.SetX(left);
    location_.SetY(top);
    size_.SetWidth(right - left);
    size_.SetHeight(bottom - top);
  }

  bool Contains(T x, T y) {
    return (x >= X() && x <= MaxX()) && (y >= Y() && y <= MaxY());
  }

 private:
  Point<T> location_;
  Size<T> size_;
};

using IntRect = Rectangle<int>;
using FloatRect = Rectangle<float>;

}  // namespace geometry
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_GEOMETRY_RECT_H_
