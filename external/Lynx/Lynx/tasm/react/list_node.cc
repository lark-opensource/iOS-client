// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tasm/react/list_node.h"

#include <unordered_map>

#include "tasm/template_assembler.h"

namespace lynx {
namespace tasm {
void ListNode::FilterComponents(std::vector<ListComponentInfo>& components,
                                TemplateAssembler* tasm) {
  // components_ and component_info must have the same size
  // this invariance is guaranteed in both AppendComponentInfo()
  // and in SetComponent().
  // local cache to boost the checking
  auto cache = std::unordered_map<std::string, bool>{};
  auto cached_not_has_component = [&cache, this, tasm](
                                      const ListComponentInfo& info) mutable {
    const auto& key = info.name_ + info.current_entry_;
    if (cache.find(key) == cache.end()) {
      cache[key] = !HasComponent(info.name_, info.current_entry_);
    }
    if (cache[key]) {
      tasm->ReportError(
          LYNX_ERROR_CODE_COMPONENT_NOT_EXIST,
          std::string{"when trying to update list component info in entry: "}
              .append(info.current_entry_)
              .append("component: ")
              .append(info.name_)
              .append(" does not exist."));
    }
    return cache[key];
  };
  components.erase(std::remove_if(components.begin(), components.end(),
                                  cached_not_has_component),
                   components.end());
}

bool ListNode::MyersDiff(const std::vector<ListComponentInfo>& old_components,
                         const std::vector<ListComponentInfo>& new_components,
                         bool force_update_all) {
  auto same_kind_cmp = [](const auto& lhs, const auto& rhs) {
    return lhs.CanBeReusedBy(rhs);
  };
  if (force_update_all) {
    platform_info_.update_actions_ = myers_diff::MyersDiff(
        (NewArch() || EnableMoveOperation()), old_components.begin(),
        old_components.end(), new_components.begin(), new_components.end(),
        same_kind_cmp, [](const auto& lhs, const auto& rhs) { return false; });
  } else {
    platform_info_.update_actions_ = myers_diff::MyersDiff(
        (NewArch() || EnableMoveOperation()), old_components.begin(),
        old_components.end(), new_components.begin(), new_components.end(),
        same_kind_cmp);
  }
  return !platform_info_.update_actions_.Empty();
}

bool ListNode::MyersDiff(const std::vector<ListComponentInfo>& old_components,
                         bool force_update_all) {
  return MyersDiff(old_components, components_, force_update_all);
}

}  // namespace tasm
}  // namespace lynx
