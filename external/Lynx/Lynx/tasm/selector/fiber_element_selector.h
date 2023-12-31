
#ifndef LYNX_TASM_SELECTOR_FIBER_ELEMENT_SELECTOR_H_
#define LYNX_TASM_SELECTOR_FIBER_ELEMENT_SELECTOR_H_

#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include "base/base_export.h"
#include "tasm/lynx_get_ui_result.h"
#include "tasm/radon/node_select_options.h"
#include "tasm/react/fiber/component_element.h"
#include "tasm/react/fiber/fiber_element.h"
#include "tasm/selector/element_selector.h"
#include "tasm/selector/select_result.h"

namespace lynx {
namespace tasm {

class LynxGetUIResult;
class SelectElementToken;

template <>
inline int32_t NodeSelectResult<FiberElement>::GetImplId(FiberElement *node) {
  return node->impl_id();
}

class FiberElementSelector : public ElementSelector {
 public:
  using ElementSelectResult = NodeSelectResult<FiberElement>;

  BASE_EXPORT_FOR_DEVTOOL static ElementSelectResult Select(
      FiberElement *root, const NodeSelectOptions &options);
  BASE_EXPORT_FOR_DEVTOOL static ElementSelectResult Select(
      const std::unique_ptr<ElementManager> &element_manager,
      const NodeSelectRoot &root, const NodeSelectOptions &options);

 private:
  virtual void SelectImpl(SelectorItem *base,
                          const std::vector<SelectElementToken> &tokens,
                          size_t token_pos,
                          const SelectImplOptions &options) override;
  void SelectImplRecursive(FiberElement *element,
                           const std::vector<SelectElementToken> &tokens,
                           size_t token_pos, const SelectImplOptions &options);
  bool IsTokenSatisfied(FiberElement *base, const SelectElementToken &token);

  virtual void SelectByElementId(SelectorItem *root,
                                 const NodeSelectOptions &options) override;

  virtual void InsertResult(SelectorItem *base) override;
  virtual bool FoundElement() override;

  void SelectInSlots(FiberElement *element,
                     const std::vector<SelectElementToken> &tokens,
                     size_t token_pos, const SelectImplOptions &options,
                     const std::string &parent_component_id);

  void UniqueAndSortResult(FiberElement *root);

  std::vector<FiberElement *> result_;
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_SELECTOR_FIBER_ELEMENT_SELECTOR_H_
