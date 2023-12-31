//  Copyright 2022 The Lynx Authors. All rights reserved.

#include "krypton_effect.h"

#include "canvas/base/log.h"
#include "effect/krypton_effect_resource_downloader.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "krypton_amazing_hooks.h"

namespace lynx {
namespace canvas {
namespace effect {
bool& EffectLoaded() {
  static bool effect_loaded = false;
  return effect_loaded;
}

bool InitEffect(const std::shared_ptr<CanvasApp>& canvas_app) {
  static bool inited = false;
  if (inited) {
    KRYPTON_LOGI("[Effect] effect has be inited");
    return true;
  }

  bool res = LoadEffectSymbols(canvas_app);
  if (res) {
    inited = true;
    EffectLoaded() = true;
  }

  effect::EffectResourceDownloader::Instance()->SetCanvasApp(canvas_app);
  return res;
}

bool InitAmazing(Napi::Env env, Napi::Object amazing) {
#if TARGET_IPHONE_SIMULATOR
  return false;
#else

  KRYPTON_LOGI("[Effect] start init amazing");
  auto canvas_app = CanvasModule::From(env)->GetCanvasApp();
  bool suc = InitEffect(canvas_app);
  if (!suc) {
    Napi::Error::New(env, "init_amazing: libeffect.so load failed")
        .ThrowAsJavaScriptException();
    return false;
  }

  GetResourceFinder(nullptr);

  int ret = 0;
  ret +=
      effect::bef_effect_javascript_binding_engine_local(env, amazing, nullptr);
  ret += effect::bef_effect_javascript_set_url_translate_func_local(
      env, URLTranslate);
  ret += effect::bef_effect_javascript_set_download_model_fuc_local(
      env, DownloadModel);
  ret += effect::bef_effect_javascript_set_download_sticker_fuc_local(
      env, DownloadSticker);
  ret += effect::bef_effect_javascript_set_resource_finder_local(
      env, GetResourceFinder(nullptr), nullptr);

  ret += effect::bef_effect_javascript_set_gl_save_func_local(env, GLStateSave);
  ret += effect::bef_effect_javascript_set_gl_restore_func_local(
      env, GLStateRestore);
  ret += effect::bef_effect_javascript_set_get_texture_func_local(
      env, GetTextureFunc);
  ret += effect::bef_effect_javascript_set_before_update_func_local(
      env, BeforeUpdateFunc);
  ret += effect::bef_effect_javascript_set_after_update_func_local(
      env, AfterUpdateFunc);

  if (ret != 0) {
    Napi::Error::New(env,
                     "init_amazing: bind symbol failed effect symbol not exist")
        .ThrowAsJavaScriptException();
    return false;
  }

  // create gl context for Amazing
  MakeSureAmazingContextCreated();
  (*ThreadLocalAmazingContextPtr())->Init();

  bool enable = true;
  effect::bef_effect_config_ab_value_local("enable_build_in_sensor_service",
                                           (void*)(&enable), 0);

  char version[20];
  effect::bef_effect_get_sdk_version_local(version, 20);
  amazing["VERSION"] = Napi::String::New(env, version);

  return true;
#endif
}

}  // namespace effect
}  // namespace canvas
}  // namespace lynx
