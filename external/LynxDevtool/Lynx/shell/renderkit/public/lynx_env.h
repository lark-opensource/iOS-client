// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ENV_H_
#define LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ENV_H_
#include <memory>
#include <string>

#include "lynx_export.h"
#include "shell/renderkit/public/lynx_config.h"

namespace lynx {

class LYNX_EXPORT LynxEnv {
 public:
  LynxEnv();
  ~LynxEnv();
  static LynxEnv& GetInstance();
  LynxConfig& Config() { return *config_; }

  static void InitLog(const std::string& log_dir);
  static void UninitLog();

  void SetCronetServerConfig(void* config);
  void* GetCronetServerConfig();

  void SetCronetEngine(void* engine);
  void* GetCronetEngine();

  void SetDevtoolEnv(const std::string& key, bool value);
  bool GetDevtoolEnv(const std::string& key, bool default_value);

  bool enable_lynx_debug();
  void set_enable_lynx_debug(bool enable_lynx_debug);

  bool enable_devtool();
  void set_enable_devtool(bool enable_devtool);

  bool enable_redbox();
  void set_enable_redbox(bool enable_redbox);

  bool GetEnableDevtoolDefault();

  std::string& GetCurrentLynxVersion();

 private:
  std::unique_ptr<LynxConfig> config_ = std::make_unique<LynxConfig>();
  void* cronet_engine_ = nullptr;
  void* cronet_server_config_ = nullptr;

  // global switch
  bool enable_lynx_debug_ = false;
  // persistent switch
  bool enable_devtool_ = false;
  bool enable_redbox_ = true;
};
}  // namespace lynx
#endif  // LYNX_SHELL_RENDERKIT_PUBLIC_LYNX_ENV_H_
