// Copyright 2021 The Lynx Authors. All rights reserved.

#include "image_data.h"

namespace lynx {
namespace canvas {

ImageData::ImageData(ExceptionState& exception_state, size_t width,
                     size_t height)
    : size_({}) {
  size_ = Validate(exception_state, width, &height);
  if (exception_state.HadException()) {
    return;
  }

  size_t data_length = size_.Area() * 4;
  void* data = malloc(data_length);
  if (data) {
    memset(data, 0, data_length);
    data_ = DataHolder::MakeWithoutCopy(data, data_length);
  }
}

ImageData::ImageData(ExceptionState& exception_state,
                     Napi::Uint8ClampedArray data, size_t width, size_t height)
    : size_({}) {
  size_ = Validate(exception_state, width, &height, &data);
  if (exception_state.HadException()) {
    return;
  }

  js_data_ref_.Reset(data, 1);
  data_ = DataHolder::MakeWithoutCopy(data.Data(), data.ByteLength());
}

ImageData::ImageData(ExceptionState& exception_state,
                     Napi::Uint8ClampedArray data, size_t width)
    : size_({}) {
  size_ = Validate(exception_state, width, nullptr, &data);
  if (exception_state.HadException()) {
    return;
  }

  js_data_ref_.Reset(data, 1);
  data_ = DataHolder::MakeWithoutCopy(data.Data(), data.ByteLength());
}

ImageData::ImageData(ImageData* other) : size_(other->size_) {
  size_t data_length = size_.Area() * 4;
  void* data = malloc(data_length);
  if (data) {
    memset(data, 0, data_length);
    data_ = DataHolder::MakeWithoutCopy(data, data_length);
  }
}

ImageData::~ImageData() = default;

ISize ImageData::Validate(ExceptionState& exception_state, size_t width,
                          const size_t* height, Napi::Uint8ClampedArray* data) {
  ISize size{};
  if (!width) {
    exception_state.SetException("The source width is zero or not a number.",
                                 piper::ExceptionState::kTypeError);
    return ISize{};
  }
  size.SetWidth(static_cast<int32_t>(width));

  if (height) {
    if (!*height) {
      exception_state.SetException("The source height is zero or not a number.",
                                   piper::ExceptionState::kTypeError);
      return ISize{};
    }

    if ((width * (*height) * 4) > std::numeric_limits<uint32_t>::max()) {
      exception_state.SetException(
          "The malloc data is too large. The maximum size is 4294967295.",
          piper::ExceptionState::kTypeError);
      return ISize{};
    }
    size.SetHeight(static_cast<int32_t>(*height));
  }

  if (data) {
    const size_t data_length_in_bytes = data->ByteLength();

    if (data_length_in_bytes > std::numeric_limits<uint32_t>::max()) {
      exception_state.SetException(
          "The input data is too large. The maximum size is 4294967295.",
          piper::ExceptionState::kTypeError);
      return ISize{};
    }

    if (!data_length_in_bytes) {
      exception_state.SetException("The input data has zero elements.",
                                   piper::ExceptionState::kTypeError);
      return ISize{};
    }

    if (data_length_in_bytes % 4) {
      exception_state.SetException(
          "The input data length is not a multiple of 4.",
          piper::ExceptionState::kTypeError);
      return ISize{};
    }

    const size_t data_length_in_pixels = data_length_in_bytes / 4;
    if (data_length_in_pixels % width) {
      exception_state.SetException(
          "The input data length is not a multiple of (4 * width).",
          piper::ExceptionState::kTypeError);
      return ISize{};
    }

    const size_t expected_height = data_length_in_pixels / width;
    if (height) {
      if (*height != expected_height) {
        exception_state.SetException(
            "The input data length is not equal to (4 * width * height).",
            piper::ExceptionState::kTypeError);
        return ISize{};
      }
    } else {
      size.SetHeight(static_cast<int32_t>(expected_height));
    }
  }

  DCHECK(!size.IsEmpty());
  return size;
}

static void finalizer(napi_env env, void* data, void* unused) { free(data); }

void ImageData::OnWrapped() {
  if (js_data_ref_.IsEmpty() && data_) {
    // transfer data owner to js
    auto array_buffer =
        Napi::ArrayBuffer::New(Env(), data_->WritableData(), data_->Size(),
                               &finalizer, (void*)nullptr);
    auto js_uint8_array = Napi::Uint8Array::New(
        Env(), array_buffer.ByteLength(), array_buffer, 0);
    js_data_ref_.Reset(js_uint8_array, 1);
  }
  DefineDataProperty();
}

void ImageData::DefineDataProperty() {
  // directly define data to js object to improve performance
  // see
  // https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/core/html/canvas/image_data.cc;l=446
  //
  // chromium use enumerable and configurable but we do not want another getter
  // method, so set it without configurable
  Napi::PropertyDescriptor property_descriptor =
      Napi::PropertyDescriptor::Value(
          "data", js_data_ref_.Value(),
          napi_property_attributes::napi_enumerable);
  JsObject().DefineProperty(property_descriptor);
}

#ifdef ENABLE_LYNX_CANVAS_SKIA
SkPixmap ImageData::GetSkPixmap() const {
  SkImageInfo image_info = SkImageInfo::Make(
      SkISize::Make(size_.width, size_.height),
      SkColorType::kRGBA_8888_SkColorType, SkAlphaType::kUnpremul_SkAlphaType);

  return SkPixmap(image_info, data_->Data(), image_info.minRowBytes());
}
#endif

const void* ImageData::GetRawData() const {
  if (!data_) {
    return nullptr;
  }

  return data_->Data();
}

}  // namespace canvas
}  // namespace lynx
