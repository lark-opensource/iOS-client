// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_STAGGERED_GRID_LAYOUT_ALGORITHM_H_
#define LYNX_STARLIGHT_LAYOUT_STAGGERED_GRID_LAYOUT_ALGORITHM_H_

#include "starlight/layout/linear_layout_algorithm.h"

namespace lynx {
namespace starlight {

class StaggeredGridLayoutAlgorithm : public LinearLayoutAlgorithm {
 public:
  StaggeredGridLayoutAlgorithm(LayoutObject*);
  ~StaggeredGridLayoutAlgorithm() = default;

 protected:
  void DetermineContainerSize() override;
  void UpdateContainerSize() override;
  void UpdateChildSize(const size_t idx) override;

 private:
  bool isHeaderFooter(LayoutObject* item);

  int column_count_;
  double cross_axis_gap_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_STAGGERED_GRID_LAYOUT_ALGORITHM_H_
