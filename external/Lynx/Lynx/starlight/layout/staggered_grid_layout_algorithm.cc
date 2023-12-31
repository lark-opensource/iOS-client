// Copyright 2019 The Lynx Authors. All rights reserved.

#include "starlight/layout/staggered_grid_layout_algorithm.h"

#include "starlight/layout/layout_object.h"
#include "starlight/layout/property_resolving_utils.h"
#include "tasm/list_component_info.h"

namespace lynx {
namespace starlight {

StaggeredGridLayoutAlgorithm::StaggeredGridLayoutAlgorithm(
    LayoutObject* container)
    : LinearLayoutAlgorithm(container) {
  auto& attr_map = container->attr_map();
  column_count_ = 1;
  if (attr_map.find(LayoutAttribute::kColumnCount) != attr_map.end()) {
    lepus::Value value = attr_map[LayoutAttribute::kColumnCount];
    column_count_ = value.IsNumber() ? static_cast<int>(value.Number()) : 1;
  }
  cross_axis_gap_ = 0;
  lepus_value tmp_value = container->GetCSSMutableStyle()->GetValue(
      tasm::kPropertyIDListCrossAxisGap);

  cross_axis_gap_ =
      tmp_value.IsNumber() ? static_cast<double>(tmp_value.Number()) : 0;
}

void StaggeredGridLayoutAlgorithm::DetermineContainerSize() {
  bool flag_change = false;
  if (!IsSLDefiniteMode(container_constraints_[kMainAxis].Mode())) {
    container_constraints_[kMainAxis] =
        OneSideConstraint::Definite(total_main_size_);
    flag_change = true;
  }

  if (!IsSLDefiniteMode(container_constraints_[kCrossAxis].Mode())) {
    container_constraints_[kCrossAxis] =
        OneSideConstraint::Definite(total_cross_size_);
    flag_change = true;
  }

  if (flag_change) UpdateContainerSize();
}

void StaggeredGridLayoutAlgorithm::UpdateContainerSize() {
  for (LayoutObject* item : inflow_items_) {
    Constraints used_container_constraints = container_constraints_;
    if (!isHeaderFooter(item) &&
        used_container_constraints[CrossAxis()].Mode() !=
            SLMeasureModeIndefinite) {
      used_container_constraints[CrossAxis()] =
          OneSideConstraint((used_container_constraints[CrossAxis()].Size() -
                             (column_count_ - 1) * cross_axis_gap_) /
                                column_count_,
                            used_container_constraints[CrossAxis()].Mode());
    }

    item->GetBoxInfo()->UpdateBoxData(used_container_constraints, *item,
                                      item->GetLayoutConfigs());
  }
}

/* Algorithm-3
 * Update child size.
 */
void StaggeredGridLayoutAlgorithm::UpdateChildSize(const size_t idx) {
  LayoutObject* child = inflow_items_[idx];
  Constraints used_container_constraints = container_constraints_;
  if (!isHeaderFooter(child) &&
      used_container_constraints[CrossAxis()].Mode() !=
          SLMeasureModeIndefinite) {
    used_container_constraints[CrossAxis()] =
        OneSideConstraint((used_container_constraints[CrossAxis()].Size() -
                           (column_count_ - 1) * cross_axis_gap_) /
                              column_count_,
                          used_container_constraints[CrossAxis()].Mode());
  }
  UpdateChildSizeInternal(idx, used_container_constraints);
}

bool StaggeredGridLayoutAlgorithm::isHeaderFooter(LayoutObject* item) {
  if (item->attr_map().find(LayoutAttribute::kListCompType) ==
      item->attr_map().end()) {
    return false;
  }
  return tasm::ListComponentInfo::IsRow(
      item->attr_map()[LayoutAttribute::kListCompType]);
}

}  // namespace starlight
}  // namespace lynx
