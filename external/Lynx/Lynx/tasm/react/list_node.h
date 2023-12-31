// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_LIST_NODE_H_
#define LYNX_TASM_REACT_LIST_NODE_H_

#include <string>
#include <vector>

#include "tasm/diff_algorithm.h"
#include "tasm/list_component_info.h"

namespace lynx {
namespace tasm {

namespace myers_diff {
struct DiffResult;
}

class TemplateAssembler;

class ListNode {
 public:
  virtual void RenderComponentAtIndex(uint32_t row,
                                      int64_t operationId = 0) = 0;
  virtual void UpdateComponent(uint32_t sign, uint32_t row,
                               int64_t operationId = 0) = 0;

  virtual void RemoveComponent(uint32_t sign) = 0;

  virtual void AppendComponentInfo(ListComponentInfo& info) = 0;

  /*
   * List New Arch API
   * prepare the component at specified id.
   * return the ui sign of the prepared component.
   */
  virtual int32_t ComponentAtIndex(uint32_t index, int64_t operationId = 0,
                                   bool enable_reuse_notification = false) {
    return 0;
  }

  /*
   * List New Arch API
   * Recycle the element of the component with specified sign.
   * Its element might be reused later upon a call of `ComponentAtIndex`.
   */
  virtual void EnqueueComponent(int32_t sign) {}

  const std::vector<uint32_t>& fullspan() const {
    return platform_info_.fullspan_;
  }

  const std::vector<uint32_t>& sticky_top() const {
    return platform_info_.stick_top_items_;
  }

  const std::vector<uint32_t>& sticky_bottom() const {
    return platform_info_.stick_bottom_items_;
  }

  const std::vector<std::string>& component_info() const {
    return platform_info_.components_;
  }

  const std::vector<double>& estimated_height() const {
    return platform_info_.estimated_heights_;
  }

  const std::vector<double>& estimated_height_px() const {
    return platform_info_.estimated_heights_px;
  }

  const std::vector<std::string>& item_keys() const {
    return platform_info_.item_keys_;
  }

  bool Diffable() const { return platform_info_.diffable_list_result_; }
  bool NewArch() const { return platform_info_.new_arch_list_; }
  bool EnableMoveOperation() const {
    return platform_info_.enable_move_operation_;
  }
  const myers_diff::DiffResult& DiffResult() const {
    return platform_info_.update_actions_;
  }
  void ClearDiffResult() { platform_info_.update_actions_.Clear(); }

 protected:
  struct PlatformInfo {
    std::vector<std::string> components_;
    std::vector<uint32_t> fullspan_;
    std::vector<uint32_t> stick_top_items_;
    std::vector<uint32_t> stick_bottom_items_;
    std::vector<double> estimated_heights_;
    std::vector<double> estimated_heights_px;

    // record the item_key of each item, so that we can figure out that whether
    // a item_key is still in our list
    std::vector<std::string> item_keys_;

    myers_diff::DiffResult update_actions_;
    bool diffable_list_result_{false};
    bool new_arch_list_{false};
    bool enable_move_operation_{false};
    bool enable_plug_{false};

    void Generate(const std::vector<ListComponentInfo>& components) {
      fullspan_.clear();
      stick_top_items_.clear();
      stick_bottom_items_.clear();
      components_.clear();
      estimated_heights_.clear();
      item_keys_.clear();

      for (auto i = size_t{}; i < components.size(); ++i) {
        components_.emplace_back(components[i].name_);
        estimated_heights_.emplace_back(components[i].estimated_height_);
        estimated_heights_px.emplace_back(components[i].estimated_height_px_);
        item_keys_.emplace_back(components[i].diff_key_.String()->str());
        if (components[i].type_ == ListComponentInfo::Type::HEADER) {
          fullspan_.push_back(static_cast<uint32_t>(i));
        } else if (components[i].type_ == ListComponentInfo::Type::FOOTER) {
          fullspan_.push_back(static_cast<uint32_t>(i));
        } else if (components[i].type_ == ListComponentInfo::Type::LIST_ROW) {
          fullspan_.push_back(static_cast<uint32_t>(i));
        }
        if (components[i].stick_top_) {
          stick_top_items_.push_back(static_cast<uint32_t>(i));
        }
        if (components[i].stick_bottom_) {
          stick_bottom_items_.push_back(static_cast<uint32_t>(i));
        }
      }
    }
  };

  PlatformInfo platform_info_;
  virtual void FilterComponents(std::vector<ListComponentInfo>& components,
                                TemplateAssembler* tasm);
  virtual bool HasComponent(const std::string& component_name,
                            const std::string& current_entry) = 0;

  std::vector<ListComponentInfo> components_;
  bool MyersDiff(const std::vector<ListComponentInfo>& old_components,
                 const std::vector<ListComponentInfo>& new_components,
                 bool force_update_all = false);
  bool MyersDiff(const std::vector<ListComponentInfo>& old_components,
                 bool force_update_all = false);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_LIST_NODE_H_
