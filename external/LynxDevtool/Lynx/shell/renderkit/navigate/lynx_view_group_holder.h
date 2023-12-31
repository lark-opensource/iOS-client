// Copyright 2021 The Lynx Authors. All rights reserved
#ifndef LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_HOLDER_H_
#define LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_HOLDER_H_
#include <string>

#include "shell/renderkit/public/lynx_view_base.h"

namespace lynx {

class LYNX_EXPORT LynxViewGroupHolder {
 public:
  explicit LynxViewGroupHolder() = default;
  virtual ~LynxViewGroupHolder() = default;

  int GetLynxViewGroupId();
  void SetLynxViewGroupId(int group_id);

  virtual void EnterLynxViewForeground(lynx::LynxViewBase* lynx_view);
  virtual void EnterLynxViewBackground(lynx::LynxViewBase* lynx_view);

  virtual lynx::LynxViewBase* CreateLynxView(const std::string& url,
                                             const std::string& param) = 0;
  virtual void ShowLynxView(lynx::LynxViewBase* lynx_view) = 0;
  virtual void HideLynxView(lynx::LynxViewBase* lynx_view) = 0;
  virtual void SetLynxViewFocus(lynx::LynxViewBase* lynx_view) = 0;
  virtual void SetLynxViewParent(lynx::LynxViewBase* lynx_view) = 0;
  virtual void SetLynxViewSize(lynx::LynxViewBase* lynx_view,
                               const lynx::LynxSize& size) = 0;
  virtual void SetLynxViewPos(lynx::LynxViewBase* lynx_view,
                              const lynx::LynxRect& rect) = 0;

 private:
  int group_id_ = 0;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_HOLDER_H_
