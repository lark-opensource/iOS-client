// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_GROUP_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_GROUP_H_

#include <memory>
#include <string>
#include <vector>

#include "lynx_export.h"
namespace lynx {

class LYNX_EXPORT LynxGroup {
 public:
  ~LynxGroup();
  static constexpr const char* kSingnleGroup = "-1";

  static std::unique_ptr<LynxGroup> Create(const std::string& name) {
    return Create(name, GenerateID(), {}, false, false);
  }

  static std::unique_ptr<LynxGroup> Create(
      const std::string& name,
      const std::vector<std::string>& preload_js_paths) {
    return Create(name, GenerateID(), preload_js_paths, false, false);
  }

  static std::unique_ptr<LynxGroup> Create(
      const std::string& name, const std::vector<std::string>& preload_js_paths,
      bool use_provider_js_env, bool enable_canvas) {
    return Create(name, GenerateID(), preload_js_paths, use_provider_js_env,
                  enable_canvas);
  }

  // only used by appbrand! other users should not set the "id"
  static std::unique_ptr<LynxGroup> Create(
      const std::string& name, std::string id,
      const std::vector<std::string>& preload_js_paths,
      bool use_provider_js_env, bool enable_canvas);

  static std::string GenerateID();

  LynxGroup(const std::string& name,
            const std::vector<std::string>& preload_js_paths);
  LynxGroup(const std::string& name, const std::string& id,
            const std::vector<std::string>& preload_js_paths,
            bool use_provider_js_env, bool enable_canvas);

  std::string GetID() { return id_; }

  bool UseProviderJsEnv() { return use_provider_js_env_; }

  bool EnableCanvas() { return enable_canvas_; }

  const std::vector<std::string>& GetPreloadJSPaths() {
    return preload_js_paths_;
  }

  std::string GetGroupName() { return group_name_; }

 private:
  std::string group_name_;
  std::string id_;
  std::vector<std::string> preload_js_paths_;
  bool use_provider_js_env_;
  bool enable_canvas_;

  static int next_id_;
};

}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_GROUP_H_
