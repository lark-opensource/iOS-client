// Copyright 2021 The Lynx Authors. All rights reserved
#ifndef LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_H_
#define LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_H_
#include <forward_list>
#include <string>

#include "shell/renderkit/navigate/lynx_view_group_holder.h"

namespace lynx {

class LynxViewGroup {
 public:
  LynxViewGroup() = default;
  virtual ~LynxViewGroup();

  int Create(LynxViewGroupHolder* group_delegate);
  void SetVisible(bool b_visible);
  void SetSize(const LynxSize& size);
  void SetPos(const LynxRect& rect);
  void SetFocus();
  void Push(const std::string& url, const std::string& param);
  void Replace(const std::string& url, const std::string& param);
  void Pop();
  void GoBack();
  void GoAhead();
  void DidEnterForeground();
  void DidEnterBackground();
  void ClearCaches();

 private:
  static int GenerateID();
  LynxViewBase* GetCurrentView();
  void ClearPopList();
  void ClearPushList();

  int group_id_ = 0;
  LynxViewGroupHolder* group_holder_ = nullptr;
  static int next_id_;
  std::forward_list<LynxViewBase*> push_list_;
  std::forward_list<LynxViewBase*> pop_list_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_GROUP_H_
