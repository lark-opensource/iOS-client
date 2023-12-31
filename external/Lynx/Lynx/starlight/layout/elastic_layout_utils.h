// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_ELASTIC_LAYOUT_UTILS_H_
#define LYNX_STARLIGHT_LAYOUT_ELASTIC_LAYOUT_UTILS_H_

#include <functional>
#include <vector>

#include "starlight/layout/direction_selector.h"
#include "starlight/layout/layout_object.h"

namespace lynx {
namespace starlight {

// Elastic layout utils is a utils class for shared usages of linear and flex
// layout algorithm. The utils class can be used to resolve items size affected
// by grow/shrink factor and min/max css properties in given available spaces.
class ElasticLayoutUtils {
 private:
  ElasticLayoutUtils() {}

 public:
  using ElasticFactorGetter = std::function<float(const LayoutObject&)>;

  // ElasticInfos is a struct used as a closure of inputs for elastic sizing
  // algorithm, with the variables definition the same as the flex box layout
  // algorithm definition in W3C html css.
  struct ElasticInfos {
    ElasticInfos(const std::vector<LayoutObject*>& targets,
                 const std::vector<float>& elastic_bases,
                 const std::vector<float>& hypothetical_sizes,
                 bool is_elastic_grow,
                 const DirectionSelector& direction_selector, size_t start,
                 size_t end)
        : targets_(targets),
          elastic_bases_(elastic_bases),
          hypothetical_sizes_(hypothetical_sizes),
          is_elastic_grow_(is_elastic_grow),
          direction_selector_(direction_selector),
          start_idx_(start),
          end_idx_(end) {}
    const std::vector<LayoutObject*>& targets_;
    const std::vector<float>& elastic_bases_;
    const std::vector<float>& hypothetical_sizes_;
    bool is_elastic_grow_;
    const DirectionSelector& direction_selector_;
    size_t start_idx_, end_idx_;
    // Use -1.f to mark this value as unset here. Sadly optional is a c++17
    // feature.
    float total_elastic_factor_override_ = -1.f;
  };

  // To compute the item sizes with given infos.
  // compute_item_size will be used to return the computed size.
  // Return value is the remaining available space.
  static float ComputeElasticItemSizes(
      ElasticInfos& elastic_infos, float available_spaces,
      ElasticFactorGetter elastic_factor_getter,
      std::vector<float>& computed_item_sizes);

  // To compute hypothetical size.
  // Computed hypothetical sizes will be stored in argument hypothetical_sizes.
  // Return value is the total hypothetical sizes.
  static float ComputeHypotheticalSizes(
      const std::vector<LayoutObject*>& targets,
      const std::vector<float>& elastic_bases,
      const DirectionSelector& direction_selector,
      std::vector<float>& hypothetical_sizes);
};
}  // namespace starlight
}  // namespace lynx
#endif  // LYNX_STARLIGHT_LAYOUT_ELASTIC_LAYOUT_UTILS_H_
