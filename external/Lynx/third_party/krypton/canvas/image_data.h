// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_IMAGE_DATA_H_
#define CANVAS_IMAGE_DATA_H_

#include "canvas/base/data_holder.h"
#include "canvas/base/size.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/exception_state.h"

#ifdef ENABLE_LYNX_CANVAS_SKIA
#include "canvas/util/skia.h"
#endif

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ExceptionState;
using piper::ImplBase;

class ImageData : public ImplBase {
 public:
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           Napi::Number width,
                                           Napi::Number height) {
    return std::unique_ptr<ImageData>(new ImageData(
        exception_state, width.Uint32Value(), height.Uint32Value()));
  }
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           Napi::Uint8ClampedArray data,
                                           Napi::Number width,
                                           Napi::Number height) {
    return std::unique_ptr<ImageData>(new ImageData(
        exception_state, data, width.Uint32Value(), height.Uint32Value()));
  }
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           Napi::Uint8ClampedArray data,
                                           Napi::Number width) {
    return std::unique_ptr<ImageData>(
        new ImageData(exception_state, data, width.Uint32Value()));
  }
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           size_t width, size_t height) {
    return std::unique_ptr<ImageData>(
        new ImageData(exception_state, width, height));
  }
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           Napi::Uint8ClampedArray data,
                                           size_t width, size_t height) {
    return std::unique_ptr<ImageData>(
        new ImageData(exception_state, data, width, height));
  }
  static std::unique_ptr<ImageData> Create(ExceptionState& exception_state,
                                           Napi::Uint8ClampedArray data,
                                           size_t width) {
    return std::unique_ptr<ImageData>(
        new ImageData(exception_state, data, width));
  }
  static std::unique_ptr<ImageData> Create(ImageData* other) {
    return std::unique_ptr<ImageData>(new ImageData(other));
  }

  void OnWrapped() override;

  ImageData(ExceptionState& exception_state, size_t width, size_t height);
  ImageData(ExceptionState& exception_state, Napi::Uint8ClampedArray data,
            size_t width, size_t height);
  ImageData(ExceptionState& exception_state, Napi::Uint8ClampedArray data,
            size_t width);
  ImageData(ImageData* other);
  ImageData(const ImageData&) = delete;
  ~ImageData() override;

  ImageData& operator=(const ImageData&) = delete;

  size_t GetWidth() { return size_.width; }
  size_t GetHeight() { return size_.height; }

#ifdef ENABLE_LYNX_CANVAS_SKIA
  SkPixmap GetSkPixmap() const;
#endif

  const void* GetRawData() const;

  static const size_t PIXEL_SIZE = 4;

 private:
  ISize Validate(ExceptionState& exception_state, size_t width,
                 const size_t* height = nullptr,
                 Napi::Uint8ClampedArray* data = nullptr);

  void DefineDataProperty();

  ISize size_;
  Napi::ObjectReference js_data_ref_;
  std::unique_ptr<DataHolder> data_{nullptr};
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_IMAGE_DATA_H_
