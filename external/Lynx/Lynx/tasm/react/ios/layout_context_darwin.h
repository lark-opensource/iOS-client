// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_REACT_IOS_LAYOUT_CONTEXT_DARWIN_H_
#define LYNX_TASM_REACT_IOS_LAYOUT_CONTEXT_DARWIN_H_

#import <Foundation/Foundation.h>

#include <memory>
#include <string>
#include <vector>

#import "LynxShadowNodeOwner.h"
#include "tasm/react/layout_context.h"
#include "tasm/react/prop_bundle.h"

namespace lynx {
namespace tasm {
class LayoutContextDarwin : public LayoutContext::PlatformImpl {
 public:
  LayoutContextDarwin(LynxShadowNodeOwner* owner);
  ~LayoutContextDarwin() override;

  int CreateLayoutNode(int sign, intptr_t layout_node_ptr,
                       const std::string& tag, PropBundle* props,
                       bool is_parent_inline_container) override;
  void UpdateLayoutNode(int sign, PropBundle* props) override;
  void InsertLayoutNode(int parent, int child, int index) override;
  void RemoveLayoutNode(int parent, int child, int index) override;
  void MoveLayoutNode(int parent, int child, int from_index,
                      int to_index) override;
  void DestroyLayoutNodes(const std::vector<int>& ids) override;
  void ScheduleLayout(base::closure) override;
  void OnLayoutBefore(int sign) override;
  void OnLayout(int sign, float left, float top, float width,
                float height) override;
  void OnLayoutFinish() override;
  void Destroy() override;
  void OnUpdateDataWithoutChange() override;
  void SetFontFaces(const CSSFontFaceTokenMap& fontFaces) override;
  void UpdateRootSize(float width, float height) override;
  std::unique_ptr<PlatformExtraBundle> GetPlatformExtraBundle(
      int32_t signature) override;
  std::unique_ptr<PlatformExtraBundleHolder> ReleasePlatformBundleHolder()
      override;

 private:
  LynxShadowNodeOwner* nodeOwner;

  LayoutContextDarwin(const LayoutContextDarwin&) = delete;
  LayoutContextDarwin& operator=(const LayoutContextDarwin&) = delete;
};
}  // namespace tasm
}  // namespace lynx
#endif  // LYNX_TASM_REACT_IOS_LAYOUT_CONTEXT_DARWIN_H_
