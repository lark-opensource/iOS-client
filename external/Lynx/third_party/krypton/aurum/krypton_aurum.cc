// Copyright 2021 The Lynx Authors. All rights reserved.

#include "aurum/krypton_aurum.h"

#include "aurum/audio_engine.h"
#include "aurum/aurum.h"
#include "aurum/config.h"
#include "aurum/embed_js.h"
#include "base/threading/task_runner_manufactor.h"
#include "canvas/base/log.h"
#include "canvas/canvas_app.h"
#include "jsbridge/bindings/canvas/canvas_module.h"

namespace lynx {
namespace canvas {

static void AuDispatchCallback(void *user_ptr, void *p,
                               void (*callback)(void *)) {
  auto canvas_app_ptr = reinterpret_cast<CanvasApp *>(user_ptr);
  canvas_app_ptr->runtime_actor()->Act(
      [p, callback,
       weak_app = std::weak_ptr<CanvasApp>(canvas_app_ptr->shared_from_this())](
          auto &impl) {
        if (callback && weak_app.lock()) {
          callback(p);
        }
      });
}

static void AuExecuteCallback(void *user_ptr, void *p,
                              void (*callback)(void *)) {
  static base::NoDestructor<fml::Thread> worker_thread("Lynx_Krypton_Aurum");
  auto weak_app = std::weak_ptr<CanvasApp>(
      reinterpret_cast<CanvasApp *>(user_ptr)->shared_from_this());
  worker_thread->GetTaskRunner()->PostTask([p, callback, weak_app]() mutable {
    if (callback && weak_app.lock()) {
      callback(p);
    }
  });
}

static void AuOnInitFail(void *user_ptr, int type, int data) {
  KRYPTON_LOGE("aurum init failed ") << type << " = " << data;
}

static void AuLoadAsync(void *user_ptr, const char *url,
                        au::PlatformLoaderDelegate *delegate) {
  KRYPTON_LOGI("AuLoadAsync called for ") << (url ?: "");
  if (!delegate || !user_ptr) {
    return;
  }

  auto canvas_app_ptr = reinterpret_cast<CanvasApp *>(user_ptr);
  canvas_app_ptr->resource_loader()->StreamLoadData(
      url, [delegate, weak_app = std::weak_ptr<CanvasApp>(
                          canvas_app_ptr->shared_from_this())](
               StreamLoadStatus status, std::unique_ptr<RawData> raw_data) {
        if (!weak_app.lock()) {
          return;
        }
        switch (status) {
          case STREAM_LOAD_START:
            delegate->OnStart(raw_data ? int64_t(raw_data->length) : -1);
            break;
          case STREAM_LOAD_DATA:
            if (raw_data) {
              delegate->OnData(raw_data->data->Data(), raw_data->length);
            }
            break;
          case STREAM_LOAD_SUCCESS_END:
            delegate->OnEnd(true, nullptr);
            break;
          case STREAM_LOAD_ERROR_END:
            delegate->OnEnd(false, nullptr);
            break;
          default:
            break;
        }
      });
}

#if OS_ANDROID
#include <dlfcn.h>
#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

static void *LoadLibByDlopen(JNIEnv *env, const std::string &library_path,
                             const char *name, bool use_jni_onload) {
  DCHECK(name && *name);
  std::string path = std::string("lib") + name + ".so";
  if (!library_path.empty()) {
    path = library_path + "/" + path;
  }
  void *handle = dlopen(path.c_str(), RTLD_GLOBAL);
  if (!handle) {
    KRYPTON_LOGI("[PluginLoader] Load ")
        << path << " failed due to " << dlerror();
    return nullptr;
  }

  void *(*jni_onload)(JavaVM *, void *) = nullptr;
  if (use_jni_onload) {
    jni_onload =
        reinterpret_cast<decltype(jni_onload)>(dlsym(handle, "JNI_OnLoad"));
    if (jni_onload) {
      JavaVM *java_vm = nullptr;
      env->GetJavaVM(&java_vm);
      jni_onload(java_vm, nullptr);
    }
  }

  KRYPTON_LOGI("[PluginLoader] Load ")
      << path << " success " << (jni_onload ? "with JNI_OnLoad" : "");
  return handle;
}

bool PostLoadPluginAudio(JNIEnv *env, const std::string &library_path) {
  static bool plugin_audio_success = false;
  if (plugin_audio_success) {
    KRYPTON_LOGI(
        "[PluginLoader] PostLoadPlugin for audio has already been loaded");
    return true;
  }

  KRYPTON_LOGI("[PluginLoader] PostLoadPlugin for audio");

  if (!library_path.empty()) {
    LoadLibByDlopen(env, library_path, "bytenn", false);
    LoadLibByDlopen(env, library_path, "ttffmpeg", false);
    void *handle = LoadLibByDlopen(env, library_path, "audioeffect", false);
    if (!handle) {
      // todo: to check safety of JNI_OnLoad in iesapplogger
      LoadLibByDlopen(env, library_path, "iesapplogger", true);
      LoadLibByDlopen(env, library_path, "audioeffect", false);
    }
  }

  void *handle = LoadLibByDlopen(env, "", "kryptonaudioeffect", true);
  if (!handle) {
    KRYPTON_LOGI("[PluginLoader] dlopen kryptonaudioeffect false");
    return false;
  }

  plugin_audio_success = true;
  KRYPTON_LOGI("[PluginLoader] PostLoadAudioPlugin success");
  return true;
}

#ifdef __cplusplus
}
#endif

#endif

struct AudioEngineHolder {
  AudioEngineHolder(uint32_t engine_id, Napi::Env env, Napi::Object exports,
                    const au::Platform &platform) {
    engine_ =
        std::make_shared<au::AudioEngine>(engine_id, env, exports, platform);
  }

  ~AudioEngineHolder() {
    if (engine_) {
      engine_->Pause();
      engine_->ForceSetRunning(false);
      engine_ = nullptr;
    }
  }

  std::shared_ptr<au::AudioEngine> Engine() const { return engine_; }

 private:
  std::shared_ptr<au::AudioEngine> engine_ = nullptr;
};

thread_local std::weak_ptr<au::AudioEngine> cached_engine;
thread_local uint32_t next_engine_id = 0;

namespace {
const uint64_t AUDIOENGINE_SAVEDATA_ID =
    reinterpret_cast<uint64_t>(&AUDIOENGINE_SAVEDATA_ID);
}

static inline std::shared_ptr<au::AudioEngine> AuGetEngine(
    const Napi::CallbackInfo &info) {
  auto id = info[0].ToNumber().Uint32Value();

  auto audio_engine = cached_engine.lock();
  if (audio_engine && audio_engine->GetIdentify() == id) {
    return audio_engine;
  }

  auto au_engine_holder = reinterpret_cast<AudioEngineHolder *>(
      info.Env().GetInstanceData(AUDIOENGINE_SAVEDATA_ID));
  if (!au_engine_holder) {
    cached_engine.reset();
    return nullptr;
  }

  cached_engine = audio_engine = au_engine_holder->Engine();
  return audio_engine;
}

std::weak_ptr<au::AudioEngine> GetAudioEngine(const Napi::CallbackInfo &info) {
  return AuGetEngine(info);
}

static Napi::Value AuInvoke(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  return engine ? engine->GetContext().Invoke(info) : Napi::Value();
}

static Napi::Value AuCapture(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  if (engine) {
    uintptr_t ptr = reinterpret_cast<uintptr_t>(engine->SetupCapture());
    uint32_t ptr_high = static_cast<uint32_t>((uint64_t)ptr >> 32);
    uint32_t ptr_low = static_cast<uint32_t>(ptr & 0xffffffff);
    auto obj = Napi::Object::New(info.Env());
    obj["_ptr_high"] = Napi::Number::New(info.Env(), ptr_high);
    obj["_ptr_low"] = Napi::Number::New(info.Env(), ptr_low);
    return obj;
  }
  return Napi::Value();
}

static Napi::Value AuCapturePause(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  if (engine) {
    engine->PauseCapture();
  }
  return Napi::Value();
}

static Napi::Value AuCaptureResume(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  if (engine) {
    engine->ResumeCapture();
  }
  return Napi::Value();
}

static Napi::Value AuEnginePause(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  if (engine && engine->IsRunning()) {
    KRYPTON_LOGI("AuEnginePause");
    engine->Pause();
  }
  return Napi::Value();
}

static Napi::Value AuEngineResume(const Napi::CallbackInfo &info) {
  auto engine = AuGetEngine(info);
  if (engine && engine->IsRunning()) {
    KRYPTON_LOGI("AuEngineResume");
    engine->Resume();
  }
  return Napi::Value();
}

static void AuInitDecoders() {
  static bool to_init = true;
  if (to_init) {
    to_init = false;

    au::decoder::Use(au::decoder::WAV());

#ifdef OS_ANDROID
#ifndef AURUM_NO_MP3
    au::decoder::Use(au::decoder::MP3());
#endif

#ifndef AURUM_NO_OGG
    au::decoder::Use(au::decoder::Vorbis());
#endif

    au::decoder::Use(au::decoder::MediaCodec());
#else
    au::decoder::Use(au::decoder::AudioToolbox());
#endif
  }
}

Napi::Value GetAurumAutoInit(Napi::Env env) {
  auto au_engine_holder = reinterpret_cast<AudioEngineHolder *>(
      env.GetInstanceData(AUDIOENGINE_SAVEDATA_ID));

  if (au_engine_holder) {
    auto au_engine = au_engine_holder->Engine();
    cached_engine = au_engine;
    return au_engine ? au_engine->GetJSExports() : Napi::Value();
  }

  AuInitDecoders();

  auto canvas_app = CanvasModule::From(env)->GetCanvasApp();

  // load java script
  char tmp[sizeof(AU_SCRIPT)];
  for (uint32_t i = 0; i < sizeof(AU_SCRIPT) - 1; i++) {
    tmp[i] = AU_SCRIPT[i] ^ (AU_SCRIPT[i] & 1 ? 0xde : 0x3c);
  }
  tmp[sizeof(AU_SCRIPT) - 1] = 0;

  auto aurum_init_func = env.RunScript(tmp, sizeof(AU_SCRIPT) - 1, "aurum.js");
  if (!aurum_init_func.IsFunction()) {
    KRYPTON_LOGE("init with aurum.js error. not function");
    return Napi::Value();
  }

  const au::Platform platform = {
      .user_ptr = canvas_app.get(),
      .Dispatch = AuDispatchCallback,
      .Execute = AuExecuteCallback,
      .OnInitFail = AuOnInitFail,
      .LoadAsync = AuLoadAsync,
  };

  uint32_t engine_id = next_engine_id++;
  Napi::Object exports = Napi::Object::New(env);
  exports["invoke"] = Napi::Function::New(env, &AuInvoke, "invoke");
  exports["capture"] = Napi::Function::New(env, &AuCapture, "capture");
  exports["capturePause"] =
      Napi::Function::New(env, &AuCapturePause, "capturePause");
  exports["captureResume"] =
      Napi::Function::New(env, &AuCaptureResume, "captureResume");
  exports["sampleRate"] = Napi::Number::New(env, AU_SAMPLE_RATE);
  exports["engine"] = Napi::Number::New(env, engine_id);
  exports["enginePause"] =
      Napi::Function::New(env, &AuEnginePause, "enginePause");
  exports["engineResume"] =
      Napi::Function::New(env, &AuEngineResume, "engineResume");

  au_engine_holder = new AudioEngineHolder(engine_id, env, exports, platform);
  env.SetInstanceData(AUDIOENGINE_SAVEDATA_ID, au_engine_holder);

  auto ret_value = aurum_init_func.As<Napi::Function>().Call({exports});
  auto au_engine = au_engine_holder->Engine();
  au_engine->SetAurumJSExports(ret_value.As<Napi::Object>());

  cached_engine = au_engine;

  KRYPTON_LOGE("init aurum success");
  return ret_value;
}

}  // namespace canvas
}  // namespace lynx
