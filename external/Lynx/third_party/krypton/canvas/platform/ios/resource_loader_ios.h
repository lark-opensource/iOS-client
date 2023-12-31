// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_RESOURCE_LOADER_IOS_H_
#define CANVAS_PLATFORM_IOS_RESOURCE_LOADER_IOS_H_

#import "KryptonApp.h"
#include "resource_loader.h"

namespace lynx {
namespace canvas {
class ResourceLoaderIOS : public ResourceLoader {
 public:
  ResourceLoaderIOS(KryptonApp* app) : app_(app){};

  void LoadData(const std::string& path, LoadRawDataCallback callback) override;

  void LoadBitmap(const std::string& path, LoadBitmapCallback callback) override;

  void StreamLoadData(const std::string& path, StreamLoadDataCallback callback) override;

  std::unique_ptr<Bitmap> DecodeDataURLSync(const std::string& data_url) override;

  virtual std::unique_ptr<RawData> EncodeBitmap(const Bitmap& bitmap, ImageType type,
                                                double encoderOptions) override;

  virtual std::string RedirectUrl(const std::string& path) override;

 private:
  void InternalLoad(const std::string& path, std::function<void(NSData*)> callback,
                    StreamLoadDataCallback stream_load_callback = nullptr);

 private:
  __weak KryptonApp* app_;
};
}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_PLATFORM_IOS_RESOURCE_LOADER_IOS_H_
