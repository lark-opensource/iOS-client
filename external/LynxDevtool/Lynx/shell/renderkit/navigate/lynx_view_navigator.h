// Copyright 2021 The Lynx Authors. All rights reserved
#ifndef LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATOR_H_
#define LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATOR_H_
#include <map>
#include <string>

#include "shell/renderkit/navigate/lynx_view_group_holder.h"
namespace lynx {

class LynxViewGroup;
class LYNX_EXPORT LynxViewNavigate {
 public:
  static LynxViewNavigate* GetInstance();

  LynxViewNavigate();

  LynxViewNavigate(const LynxViewNavigate&) = delete;
  LynxViewNavigate& operator=(const LynxViewNavigate&) = delete;
  LynxViewNavigate(LynxViewNavigate&&) = delete;
  LynxViewNavigate& operator=(LynxViewNavigate&&) = delete;

  void RegisterLynxViewGroupHolder(
      LynxViewGroupHolder*
          group_delegate);  // return lynx view group id default 0
  void SetVisible(bool b_visible, int group_id = 0);
  void SetSize(const LynxSize& size, int group_id = 0);
  void SetPos(const LynxRect& rect, int group_id = 0);
  void SetFocus(int group_id = 0);
  void NavigateTo(const std::string& url, const std::string& param,
                  int group_id = 0);
  void Replace(const std::string& url, const std::string& param,
               int group_id = 0);
  void Refresh(const std::string& url, const std::string& param,
               int group_id = 0);
  void Pop(int group_id = 0);
  void GoBack(int group_id = 0);
  void GoAhead(int group_id = 0);
  void DidEnterForeground(int group_id = 0);
  void DidEnterBackground(int group_id = 0);
  void ClearCaches(int group_id = 0);  // need clear before object deleted
  void ClearAllCaches();               // need clear before process exit

 private:
  LynxViewGroup* GetLynxViewGroup(int group_id);

  std::map<int, LynxViewGroup*> lynx_view_group_map_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_NAVIGATE_LYNX_VIEW_NAVIGATOR_H_
