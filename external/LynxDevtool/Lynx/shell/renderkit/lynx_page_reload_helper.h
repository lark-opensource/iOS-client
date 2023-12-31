// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_LYNX_PAGE_RELOAD_HELPER_H_
#define LYNX_SHELL_RENDERKIT_LYNX_PAGE_RELOAD_HELPER_H_

#include <memory>
#include <string>
#include <vector>

#include "shell/renderkit/public/lynx_view_base.h"

namespace lynx {
namespace devtool {

class LynxPageReloadHelper {
 public:
  explicit LynxPageReloadHelper(LynxViewBase* view);
  virtual ~LynxPageReloadHelper() = default;

  void LoadFromLocalFile(const std::vector<uint8_t>& tem,
                         const std::string& url, LynxTemplateData* init_data);
  void LoadFromURL(const std::string& url, LynxTemplateData* init_data);

  std::string GetURL();

  void ReloadLynxView(bool ignore_cache);
  void NavigateLynxView(const std::string& url);

  void AttachLynxView(LynxViewBase* lynx_view);

  std::shared_ptr<LynxTemplateData> GetTemplateData();

 private:
  LynxViewBase* lynx_view_;
  bool init_with_binary_;
  std::vector<uint8_t> binary_;
  bool init_with_url_;
  std::string url_;

  std::shared_ptr<LynxTemplateData> init_data_;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_LYNX_PAGE_RELOAD_HELPER_H_
