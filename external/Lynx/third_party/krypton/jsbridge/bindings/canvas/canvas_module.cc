// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/bindings/canvas/canvas_module.h"

#include "canvas/base/log.h"
#include "canvas/canvas_app.h"
#include "canvas/canvas_ui_proxy.h"
#include "canvas/gpu/gl_initializer.h"
#include "canvas/media/media_stream.h"
#include "canvas/platform/camera_context.h"
#include "canvas/platform/permission_manager.h"
#include "canvas/text/font_util.h"
#include "canvas/util/utils.h"
#include "config/config.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_event.h"
#include "jsbridge/bindings/canvas/napi_event_target.h"
#include "jsbridge/bindings/canvas/napi_get_user_media_callback.h"
#include "jsbridge/bindings/canvas/napi_gyroscope.h"
#include "jsbridge/bindings/canvas/napi_image_data.h"
#include "jsbridge/bindings/canvas/napi_image_element.h"
#include "jsbridge/bindings/canvas/napi_media_stream.h"
#include "jsbridge/bindings/canvas/napi_preload_plugin_callback.h"
#include "jsbridge/bindings/canvas/napi_read_file_callback.h"
#include "jsbridge/bindings/canvas/napi_request_permission_callback.h"
#include "jsbridge/bindings/canvas/napi_video_element.h"
#include "jsbridge/bindings/canvas/napi_webgl_active_info.h"
#include "jsbridge/bindings/canvas/napi_webgl_buffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_framebuffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_program.h"
#include "jsbridge/bindings/canvas/napi_webgl_renderbuffer.h"
#include "jsbridge/bindings/canvas/napi_webgl_rendering_context.h"
#include "jsbridge/bindings/canvas/napi_webgl_shader.h"
#include "jsbridge/bindings/canvas/napi_webgl_shader_precision_format.h"
#include "jsbridge/bindings/canvas/napi_webgl_texture.h"
#include "jsbridge/bindings/canvas/napi_webgl_uniform_location.h"
#include "jsbridge/napi/callback_helper.h"
#include "jsbridge/napi/napi_bench_object.h"
#include "third_party/fml/make_copyable.h"
#ifdef __ANDROID__
#include "canvas/platform/android/plugin_loader_android.h"
#endif

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "jsbridge/bindings/canvas/napi_canvas_gradient.h"
#include "jsbridge/bindings/canvas/napi_canvas_pattern.h"
#include "jsbridge/bindings/canvas/napi_canvas_rendering_context_2d.h"
#include "jsbridge/bindings/canvas/napi_dom_matrix.h"
#include "jsbridge/bindings/canvas/napi_path_2d.h"
#include "jsbridge/bindings/canvas/napi_text_metrics.h"
#else
#include "jsbridge/bindings/canvas/napi_canvas_gradient.h"
#include "jsbridge/bindings/canvas/napi_canvas_pattern.h"
#include "jsbridge/bindings/canvas/napi_canvas_rendering_context_2d.h"
#endif

#if ENABLE_KRYPTON_EFFECT
#include "effect/krypton_effect_bindings.h"
#endif

#if ENABLE_KRYPTON_AURUM
#include "aurum/krypton_aurum.h"
#endif

#if ENABLE_KRYPTON_RECORDER
#include "recorder/media_recorder_bindings.h"
#endif

#if ENABLE_KRYPTON_RTC
#include "rtc/krypton_rtc_helper.h"
#endif

using lynx::piper::CallbackHelper;

namespace lynx {
namespace canvas {

namespace {

const uint64_t kCanvasModuleID = reinterpret_cast<uint64_t>(&kCanvasModuleID);

enum ResourceType { kText = 1, kArrayBuffer, kImage };

Napi::Value GetUserMediaCamera(const Napi::CallbackInfo& info) {
  if (info.Length() < 2) {
    Napi::TypeError::New(
        info.Env(), "Not enough arguments for GetUserMediaCamera, expecting: 2")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto option =
      piper::NativeValueTraits<piper::IDLObject>::NativeValue(info[0]);
  auto callback = piper::NativeValueTraits<
      piper::IDLFunction<NapiGetUserMediaCallback>>::NativeValue(info[1]);
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  CameraContext::RequestUserMedia(
      canvas_app, option,
      fml::MakeCopyable([canvas_app, callback = std::move(callback)](
                            std::unique_ptr<VideoContext> context,
                            std::optional<std::string> err) mutable {
        canvas_app->runtime_task_runner()->PostTask(fml::MakeCopyable(
            [context = std::move(context), err = std::move(err),
             callback = std::move(callback)]() mutable {
              bool valid;
              Napi::Env env = callback->Env(&valid);
              if (!valid) {
                KRYPTON_LOGE("GetUserMediaCamera but env is not valid.");
                return;
              }
              Napi::ContextScope cs(env);
              Napi::HandleScope hs(env);
              auto media_stream = std::make_unique<MediaStream>(
                  MediaStream::Type::Camera, std::move(context));
              callback->Invoke(std::move(media_stream), std::move(err));
            }));
      }));
  return Napi::Value();
}

void LoadAsyncImpl(const std::string& path, uint32_t format,
                   std::unique_ptr<NapiReadFileCallback> cb) {
  Napi::Env env = cb->Env(nullptr);
  auto canvas_app = CanvasModule::From(env)->GetCanvasApp();
  auto loader = canvas_app->resource_loader();
  auto actor = canvas_app->runtime_actor();
  auto callback =
      fml::MakeCopyable([cb = std::move(cb), format,
                         actor](std::unique_ptr<RawData> raw_data) mutable {
        actor->Act([cb = std::move(cb), format,
                    raw_data = std::move(raw_data)](auto& impl) {
          bool valid;
          Napi::Env env = cb->Env(&valid);
          if (!valid) {
            KRYPTON_LOGE("loadAsyncImpl but env is not valid.");
            return;
          }
          Napi::ContextScope cs(env);
          Napi::HandleScope hs(env);
          if (!raw_data) {
            // return false
            cb->Invoke(Napi::Boolean::New(env, false));
            return;
          }
          switch (format) {
            case kText: {
              // napi new string will copy data !!!
              auto data = (char*)raw_data->data->Data();
              auto text = Napi::String::New(env, data, raw_data->length);
              cb->Invoke(text);
              break;
            }
            default:
              // napi new arraybuffer will NOT copy data, call
              // Dataholder->Release to make sure memory not free
              void* data = raw_data->data->Release();
              auto arrayBuffer = Napi::ArrayBuffer::New(
                  env, data, raw_data->length,
                  [](napi_env env, void* napi_data, void* a) {
                    free(napi_data);
                  },
                  (void*)nullptr);
              cb->Invoke(arrayBuffer);
              break;
          }
        });
      });
  loader->LoadData(path, callback);
}

Napi::Value LoadDataUrlImpl(const Napi::Env& env, const std::string& path,
                            uint32_t format) {
  KRYPTON_LOGI("load data url with type") << format;
  auto src_size = path.size();
  auto size = Base64::dec_size(src_size);

  auto data_holder = DataHolder::MakeWithMalloc(size);
  auto ret = Base64::decode(path.c_str(), src_size,
                            (uint8_t*)data_holder->Data(), size);
  if (ret > 0) {
    KRYPTON_LOGI("Decode success with format: ") << format;
    if (format == kArrayBuffer) {
      auto arrayBuffer = Napi::ArrayBuffer::New(
          env, data_holder->Release(), size,
          [](napi_env env, void* napi_data, void* a) { free(napi_data); },
          (void*)nullptr);
      return arrayBuffer;
    } else if (format == kText) {
      return Napi::String::New(env, (char*)data_holder->Data(), size);
    }
  }
  return env.Undefined();
}

Napi::Value LoadAsync(const Napi::CallbackInfo& info) {
  if (info.Length() < 3) {
    Napi::TypeError::New(
        info.Env(), "Not enough arguments for Utils.LoadAsync(), expecting: 3")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto arg0_path =
      piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0], 0);

  auto arg1_format =
      piper::NativeValueTraits<piper::IDLNumber>::NativeValue(info[1], 1);

  auto arg2_cb = piper::NativeValueTraits<
      piper::IDLFunction<NapiReadFileCallback>>::NativeValue(info[2], 2);

  if (info.Env().IsExceptionPending()) {
    return Napi::Value();
  }
  LoadAsyncImpl(std::move(arg0_path), arg1_format, std::move(arg2_cb));
  return Napi::Value();
}

Napi::Value SetSkipErrCheck(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    Napi::TypeError::New(
        info.Env(), "Not enough arguments for setSkipErrCheck(), expecting: 1")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto arg0_skip =
      piper::NativeValueTraits<piper::IDLBoolean>::NativeValue(info[0], 0);

  if (info.Env().IsExceptionPending()) {
    return Napi::Value();
  }

  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  canvas_app->GetCanvasOptions()->skip_error_check = arg0_skip;
  return Napi::Value();
}

Napi::Value SetOption(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    Napi::TypeError::New(
        info.Env(), "Not enough arguments for setSkipErrCheck(), expecting: 1")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto option =
      piper::NativeValueTraits<piper::IDLObject>::NativeValue(info[0]);

  if (info.Env().IsExceptionPending()) {
    return Napi::Value();
  }

  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  canvas_app->UpdateCanvasOptions(option);
  return Napi::Value();
}

Napi::Value GetAurum(const Napi::CallbackInfo& info) {
#if ENABLE_KRYPTON_AURUM
  return GetAurumAutoInit(info.Env());
#else
  return Napi::Value();
#endif
}

Napi::Value RequestUserMediaPermission(const Napi::CallbackInfo& info) {
  if (info.Length() < 2) {
    Napi::TypeError::New(
        info.Env(),
        "Not enough arguments for RequestUserMediaPermission, expecting: 2")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto option =
      piper::NativeValueTraits<piper::IDLObject>::NativeValue(info[0]);

  auto callback = piper::NativeValueTraits<
      piper::IDLFunction<NapiRequestPermissionCallback>>::NativeValue(info[1]);

  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  auto response_callback = fml::MakeCopyable(
      [canvas_app, callback = std::move(callback)](bool accepted) mutable {
        canvas_app->runtime_task_runner()->PostTask(fml::MakeCopyable(
            [accepted, callback = std::move(callback)]() mutable {
              bool valid;
              Napi::Env env = callback->Env(&valid);
              if (!valid) {
                KRYPTON_LOGE(
                    "RequestUserMediaPermission but env is not valid.");
                return;
              }
              Napi::ContextScope cs(env);
              Napi::HandleScope hs(env);
              callback->Invoke(accepted);
            }));
      });

  if (option.Get("audio").ToBoolean().Value()) {
    PermissionManager::RequestMicrophone(canvas_app, response_callback);
  } else {
    PermissionManager::RequestCamera(canvas_app, response_callback);
  }
  return Napi::Value();
}

Napi::Value LoadDataUrl(const Napi::CallbackInfo& info) {
  if (info.Length() < 2) {
    Napi::TypeError::New(
        info.Env(),
        "Not enough arguments for Utils.LoadDataUrl(), expecting: 2")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto arg0_path =
      piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0], 0);

  auto arg1_format =
      piper::NativeValueTraits<piper::IDLNumber>::NativeValue(info[1], 1);

  if (info.Env().IsExceptionPending()) {
    return Napi::Value();
  }
  return LoadDataUrlImpl(info.Env(), std::move(arg0_path), arg1_format);
}

Napi::Value GetSurfaceInfoFromUISync(const Napi::CallbackInfo& info) {
  if (info.Length() < 1) {
    Napi::TypeError::New(
        info.Env(), "Not enough arguments for GetSurfaceInfoSync, expecting: 1")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto id = piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0]);

  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  auto surface_info =
      canvas_app->GetUIProxy()->GetFirstSurfaceAbstractByIdSync(id);
  if (surface_info.has_value()) {
    auto result = Napi::Object::New(info.Env());
    result["width"] = surface_info->width;
    result["height"] = surface_info->height;
    return result;
  }
  return info.Env().Undefined();
}

Napi::Value PreloadPlugin(const Napi::CallbackInfo& info) {
  if (info.Length() < 2) {
    Napi::TypeError::New(info.Env(),
                         "Not enough arguments for PreloadPlugin, expecting: 2")
        .ThrowAsJavaScriptException();
    return Napi::Value();
  }

  auto plugin =
      piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0]);
  auto js_callback = piper::NativeValueTraits<
      piper::IDLFunction<NapiPreloadPluginCallback>>::NativeValue(info[1]);
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();

#ifdef __ANDROID__
  auto callback =
      fml::MakeCopyable([canvas_app, js_callback = std::move(js_callback)](
                            bool succeed, std::string err_message) mutable {
        canvas_app->runtime_task_runner()->PostTask(
            fml::MakeCopyable([succeed, err_message,
                               js_callback = std::move(js_callback)]() mutable {
              bool valid;
              Napi::Env env = js_callback->Env(&valid);
              if (!valid) {
                KRYPTON_LOGE("PreloadPlugin but env is not valid.");
                return;
              }
              Napi::ContextScope cs(env);
              Napi::HandleScope hs(env);
              js_callback->Invoke(succeed, err_message);
            }));
      });

  PluginLoaderAndroid::LoadPlugin(canvas_app, plugin, callback);
#else
  js_callback->Invoke(true, "");
#endif
  return info.Env().Undefined();
}

Napi::Value TriggerGC(const Napi::CallbackInfo& info) {
  auto runtime =
      piper::NapiEnvironment::From(info.Env())->GetJSRuntime().lock();

  if (runtime) {
    TRACE_EVENT(LYNX_TRACE_CATEGORY, "TriggerGC");
    runtime->RequestGC();
  }

  return info.Env().Undefined();
}

Napi::Value Initialize(const Napi::CallbackInfo& info) {
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  GLInitializer::Instance().InitOnJSThreadAsync(canvas_app->gpu_task_runner());
  return info.Env().Undefined();
}

Napi::Object Load(Napi::Env env, Napi::Object krypton) {
  CanvasModule::RegisterClasses(env, krypton);

  krypton["_loadAsync"] = Napi::Function::New(env, &LoadAsync, "_loadAsync");
  krypton["setSkipErrCheck"] =
      Napi::Function::New(env, &SetSkipErrCheck, "setSkipErrCheck");
  krypton["setOptions"] = Napi::Function::New(env, &SetOption, "setOptions");
  krypton["loadFont"] = Napi::Function::New(env, &LoadFont, "loadFont");
  krypton["_getAurum"] = Napi::Function::New(env, &GetAurum, "_getAurum");
  krypton["_loadDataUrl"] =
      Napi::Function::New(env, &LoadDataUrl, "_loadDataUrl");
  krypton["_getSurfaceInfoFromUISync"] = Napi::Function::New(
      env, &GetSurfaceInfoFromUISync, "_getSurfaceInfoFromUISync");
#if !defined(OS_WIN) || !defined(ENABLE_RENDERKIT_CANVAS)
  krypton["_getUserMediaCamera"] =
      Napi::Function::New(env, &GetUserMediaCamera, "_getUserMediaCamera");
  krypton["_requestUserMediaPermission"] = Napi::Function::New(
      env, &RequestUserMediaPermission, "_requestUserMediaPermission");
  krypton["initializeAsync"] =
      Napi::Function::New(env, &Initialize, "initializeAsync");
#endif

  krypton["preloadPlugin"] =
      Napi::Function::New(env, &PreloadPlugin, "preloadPlugin");
  krypton["triggerGC"] = Napi::Function::New(env, &TriggerGC, "triggerGC");

#if ENABLE_KRYPTON_EFFECT
  effect::RegisterEffectBindings(krypton);
#endif

#if ENABLE_KRYPTON_RECORDER
  recorder::RegisterMediaRecorderBindings(krypton);
#endif

#if ENABLE_KRYPTON_RTC
  rtc::RtcHelper::Instance().RegisterRtcBindings(krypton);
#endif
  return krypton;
}

// ['napiLoaderOnRT' + runtimeID].load('krypton')
NODE_API_MODULE(krypton, Load)

}  // namespace

// static
CanvasModule* CanvasModule::From(Napi::Env env) {
  return env.GetInstanceData<CanvasModule>(kCanvasModuleID);
}

void CanvasModule::Install(Napi::Env env) {
  env.SetInstanceData(
      kCanvasModuleID, this,
      [](napi_env env, void* finalize_data, void* finalize_hint) {
        delete reinterpret_cast<CanvasModule*>(finalize_data);
      },
      nullptr);
}

CanvasModule::CanvasModule(std::shared_ptr<CanvasApp> app) : app_(app) {}

void CanvasModule::RegisterClasses(Napi::Env env, Napi::Object& target) {
#if defined(OS_WIN) && defined(ENABLE_RENDERKIT_CANVAS)
  // Napi classes for Renderkit Windows
  NapiCanvasElement::Install(env, target);
  NapiEvent::Install(env, target);
  NapiEventTarget::Install(env, target);
  NapiImageData::Install(env, target);
  NapiImageElement::Install(env, target);
  NapiVideoElement::Install(env, target);
  NapiCanvasGradient::Install(env, target);
  NapiCanvasPattern::Install(env, target);
  NapiCanvasRenderingContext2D::Install(env, target);

#else
  NapiCanvasElement::Install(env, target);
  NapiEvent::Install(env, target);
  NapiEventTarget::Install(env, target);
  NapiImageData::Install(env, target);
  NapiImageElement::Install(env, target);
  NapiVideoElement::Install(env, target);

  NapiWebGLActiveInfo::Install(env, target);
  NapiWebGLBuffer::Install(env, target);
  NapiWebGLFramebuffer::Install(env, target);
  NapiWebGLProgram::Install(env, target);
  NapiWebGLRenderbuffer::Install(env, target);
  NapiWebGLRenderingContext::Install(env, target);
  NapiWebGLShader::Install(env, target);
  NapiWebGLShaderPrecisionFormat::Install(env, target);
  NapiWebGLTexture::Install(env, target);
  NapiWebGLUniformLocation::Install(env, target);

#ifdef ENABLE_LYNX_CANVAS_SKIA
  NapiPath2D::Install(env, target);
  NapiCanvasGradient::Install(env, target);
  NapiDOMMatrix::Install(env, target);
  NapiCanvasPattern::Install(env, target);
  NapiTextMetrics::Install(env, target);
  NapiCanvasRenderingContext2D::Install(env, target);
#else
  NapiCanvasGradient::Install(env, target);
  NapiCanvasPattern::Install(env, target);
  NapiCanvasRenderingContext2D::Install(env, target);
#endif
  piper::testing::BenchObject::Install(env, target, 30);
  NapiGyroscope::Install(env, target);
#endif
}

}  // namespace canvas
}  // namespace lynx
