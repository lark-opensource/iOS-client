// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_RESOURCE_LOADER_H_
#define CANVAS_PLATFORM_RESOURCE_LOADER_H_

#include <cmath>
#include <functional>
#include <string>

#include "canvas/base/data_holder.h"
#include "canvas/bitmap.h"
#include "third_party/fml/synchronization/waitable_event.h"

namespace lynx {
namespace canvas {

struct RawData {
  std::unique_ptr<DataHolder> data{nullptr};
  size_t length{0};
};

typedef std::function<void(std::unique_ptr<RawData>)> LoadRawDataCallback;
typedef std::function<void(std::unique_ptr<Bitmap>)> LoadBitmapCallback;

enum StreamLoadStatus {
  STREAM_LOAD_START,
  STREAM_LOAD_DATA,
  STREAM_LOAD_SUCCESS_END,
  STREAM_LOAD_ERROR_END,
};
typedef std::function<void(StreamLoadStatus status, std::unique_ptr<RawData>)>
    StreamLoadDataCallback;

class ResourceLoader {
 public:
  enum ImageType { PNG = 0, JPEG = 1 };

  virtual ~ResourceLoader() = default;

  virtual void LoadData(const std::string& path,
                        LoadRawDataCallback callback) = 0;

  virtual void LoadBitmap(const std::string& path,
                          LoadBitmapCallback callback) = 0;

  virtual std::unique_ptr<Bitmap> DecodeDataURLSync(
      const std::string& data_url) {
    return nullptr;
  };

  virtual void StreamLoadData(const std::string& path,
                              StreamLoadDataCallback callback) = 0;

  virtual std::unique_ptr<RawData> EncodeBitmap(const Bitmap& bitmap,
                                                ImageType type,
                                                double encoderOptions) = 0;

  virtual std::string RedirectUrl(const std::string& path) = 0;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_RESOURCE_LOADER_H_
