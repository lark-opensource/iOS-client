// Copyright 2021 The Lynx Authors. All rights reserved.

#include "font_util.h"

#include "canvas/base/data_holder.h"
#include "canvas/canvas_app.h"
#include "canvas/text/font_collection.h"
#include "jsbridge/bindings/canvas/canvas_module.h"
#include "jsbridge/napi/native_value_traits.h"

#ifdef ENABLE_RENDERKIT_CANVAS
#include "third_party/renderkit/include/rk_canvas.h"
#endif

namespace lynx {
namespace canvas {

Napi::Value LoadFont(const Napi::CallbackInfo &info) {
  if (info.Length() < 2) {
    Napi::TypeError::New(info.Env(),
                         "Not enough arguments for LoadFont(), expecting: 2")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::From(info.Env(), false);
  }

  if (!info[0].IsString()) {
    Napi::TypeError::New(info.Env(), "first argument must be string")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::From(info.Env(), false);
  }

  if (!info[1].IsArrayBuffer()) {
    Napi::TypeError::New(info.Env(), "second argument must be arraybuffer")
        .ThrowAsJavaScriptException();
    return Napi::Boolean::From(info.Env(), false);
  }

  auto family_name =
      piper::NativeValueTraits<piper::IDLString>::NativeValue(info[0]);
  auto data =
      piper::NativeValueTraits<piper::IDLArrayBuffer>::NativeValue(info[1]);

#ifdef ENABLE_RENDERKIT_CANVAS
  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  std::string family = family_name;
  RKCanvasLoadFont(canvas_app->GetHostImpl(), family.c_str(),
                   static_cast<uint8_t *>(data.Data()), data.ByteLength());
#else
  std::unique_ptr<DataHolder> data_holder(
      DataHolder::MakeWithCopy(data.Data(), data.ByteLength()));

  auto canvas_app = CanvasModule::From(info.Env())->GetCanvasApp();
  auto font_collection = canvas_app->GetFontCollection();
  font_collection->AddNormalTypeface(family_name, std::move(data_holder));
#endif

  return Napi::Boolean::From(info.Env(), true);
}
}  // namespace canvas
}  // namespace lynx
