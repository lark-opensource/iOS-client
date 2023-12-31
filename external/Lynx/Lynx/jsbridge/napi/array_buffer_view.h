// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_ARRAY_BUFFER_VIEW_H_
#define LYNX_JSBRIDGE_NAPI_ARRAY_BUFFER_VIEW_H_

#include "jsbridge/napi/shim/shim_napi.h"

namespace lynx {
namespace piper {

class ArrayBufferView {
 public:
  static ArrayBufferView From(const Napi::TypedArray& typed_array) {
    return ArrayBufferView(typed_array);
  }
  static ArrayBufferView From(const Napi::DataView& data_view) {
    return ArrayBufferView(data_view);
  }

  ArrayBufferView(const Napi::TypedArray& typed_array)
      : buffer_(typed_array.ArrayBuffer()),
        length_(typed_array.ByteLength()),
        offset_(typed_array.ByteOffset()) {
    switch (typed_array.TypedArrayType()) {
      case napi_int8_array:
        type_ = kTypeInt8;
        break;
      case napi_uint8_array:
        type_ = kTypeUint8;
        break;
      case napi_uint8_clamped_array:
        type_ = kTypeUint8Clamped;
        break;
      case napi_int16_array:
        type_ = kTypeInt16;
        break;
      case napi_uint16_array:
        type_ = kTypeUint16;
        break;
      case napi_int32_array:
        type_ = kTypeInt32;
        break;
      case napi_uint32_array:
        type_ = kTypeUint32;
        break;
      case napi_float32_array:
        type_ = kTypeFloat32;
        break;
      case napi_float64_array:
        type_ = kTypeFloat64;
        break;
      case napi_bigint64_array:
        type_ = kTypeBigInt64;
        break;
      case napi_biguint64_array:
        type_ = kTypeBigUint64;
        break;
      default:
        NOTREACHED();
        break;
    }
  }
  ArrayBufferView(const Napi::DataView& data_view)
      : buffer_(data_view.ArrayBuffer()),
        type_(kTypeDataView),
        length_(data_view.ByteLength()),
        offset_(data_view.ByteOffset()) {}
  ArrayBufferView() : type_(kTypeEmpty) {}

  enum ViewType {
    kTypeEmpty,
    kTypeInt8,
    kTypeUint8,
    kTypeUint8Clamped,
    kTypeInt16,
    kTypeUint16,
    kTypeInt32,
    kTypeUint32,
    kTypeFloat32,
    kTypeFloat64,
    kTypeBigInt64,
    kTypeBigUint64,
    kTypeDataView
  };

  ViewType GetType() { return type_; }

  Napi::ArrayBuffer& ArrayBuffer() { return buffer_; }

  // Gets a pointer to the data buffer.
  void* Data() { return reinterpret_cast<uint8_t*>(buffer_.Data()) + offset_; }

  // Gets the length of the array buffer in bytes.
  size_t ByteLength() { return length_; }

  bool IsUint8Array() const { return type_ == kTypeUint8; }

  bool IsUint8ClampedArray() const { return type_ == kTypeUint8Clamped; }

  bool IsInt8Array() const { return type_ == kTypeInt8; }

  bool IsUint16Array() const { return type_ == kTypeUint16; }

  bool IsInt16Array() const { return type_ == kTypeInt16; }

  bool IsUint32Array() const { return type_ == kTypeUint32; }

  bool IsInt32Array() const { return type_ == kTypeInt32; }

  bool IsFloat32Array() const { return type_ == kTypeFloat32; }

  bool IsFloat64Array() const { return type_ == kTypeFloat64; }

  bool IsEmpty() const { return type_ == kTypeEmpty; }

 private:
  Napi::ArrayBuffer buffer_;
  ViewType type_;
  size_t length_;
  size_t offset_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_ARRAY_BUFFER_VIEW_H_
