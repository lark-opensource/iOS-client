// Copyright 2023 The Lynx Authors. All rights reserved.

#include "animax/resource/composition_fetcher.h"

#include "animax/base/log.h"
#include "animax/bridge/animax_element.h"
#include "animax/parser/composition_parser.h"
#include "third_party/fml/make_copyable.h"

namespace lynx {
namespace animax {

CompositionFetcher::CompositionFetcher(
    const std::weak_ptr<AnimaXElement>& element,
    const std::weak_ptr<lynx::canvas::CanvasApp>& canvas_app, float scale)
    : element_(element), canvas_app_(canvas_app), scale_(scale) {}

void CompositionFetcher::RequestSource(const std::string& src,
                                       const DataCallback& callback) {
  if (!callback) {
    ANIMAX_LOGE("RequestSource without a callback");
    return;
  }
  ANIMAX_LOGI("start to request animax resource: ") << src;
  auto length = src.length();
  if (!length || src.rfind("http", 0) != 0) {
    callback(nullptr, "url is invalid");
    return;
  }

  // Strip url resource query parameters
  auto position = src.find("?", 0);
  if (position != std::string::npos) {
    length = position;
  }

  auto dot_json_length = strlen(kJson);
  if (length >= dot_json_length &&
      src.compare(length - dot_json_length, dot_json_length, kJson) == 0) {
    // Request json format animation resource
    RequestJson(src, callback);
  } else {
    callback(nullptr, "url has unsupported file extension");
  }
}

void CompositionFetcher::SetSrcPolyfill(
    const std::unordered_map<std::string, std::string>& polyfill) {
  polyfill_map_ = polyfill;
}

void CompositionFetcher::RequestJson(const std::string& src,
                                     const DataCallback& callback) {
  std::shared_ptr<canvas::CanvasApp> canvas_app = canvas_app_.lock();
  lynx::canvas::ResourceLoader* loader =
      canvas_app ? canvas_app->resource_loader() : nullptr;

  if (!loader) {
    callback(nullptr, "internal error, loader is nullptr");
    return;
  }

  if (!current_src_.empty() && current_src_ != src) {
    ANIMAX_LOGI("src has changed, reset the record");
    std::shared_ptr<AnimaXElement> element = element_.lock();
    if (element) {
      element->GetRecord().Reset();
    }
  }

  current_src_ = src;
  LoadJson(src, *loader, callback);
}

void CompositionFetcher::LoadJson(const std::string& src,
                                  canvas::ResourceLoader& loader,
                                  const DataCallback& callback) {
  Record(ParseRecord::Stage::kRequestStart);
  loader.LoadData(src, [callback](std::unique_ptr<lynx::canvas::RawData> data) {
    ANIMAX_LOGI("LoadJson received data");
    if (!data || !data->data || !data->data->Data() || !data->length) {
      callback(nullptr, "received data is empty");
      return;
    }
    callback(std::move(data), "");
  });
}

void CompositionFetcher::ParseJson(const char* json, size_t length,
                                   const CompositionCallback& callback) {
  if (!callback) {
    return;
  }

  // The core process to parse json format to composition model
  Record(ParseRecord::Stage::kParseCompositionStart);
  auto composition = CompositionParser::Instance().Parse(json, length, scale_);
  Record(ParseRecord::Stage::kParseCompositionEnd);

  // Check image and font assets are ready in composition
  WaitOnAssetAttach(*composition,
                    [callback, composition]() { callback(composition); });
}

void CompositionFetcher::WaitOnAssetAttach(
    CompositionModel& model, const std::function<void()>& callback) {
  Record(ParseRecord::Stage::kLoadAssetStart);
  waiting_image_count_ = model.GetImages().size();
  waiting_font_count_ = model.GetFonts().size();

  // If no image and font asset, return directly
  if (IsAssetReady() || current_src_.empty()) {
    Record(ParseRecord::Stage::kLoadAssetEnd);
    callback();
    return;
  }

  std::shared_ptr<canvas::CanvasApp> canvas_app = canvas_app_.lock();
  if (!canvas_app) {
    ANIMAX_LOGE("canvas_app is null, WaitOnAssetAttach failed");
    return;
  }

  // Get loader to load image and font resource
  auto loader = canvas_app->resource_loader();
  if (!loader) {
    ANIMAX_LOGI("loader is null, WaitOnAssetAttach failed");
    return;
  }

  ANIMAX_LOGI("start to waiting on image and font assets. image size: ")
      << std::to_string(waiting_image_count_)
      << ", font size: " << std::to_string(waiting_font_count_);

  std::string url_prefix = current_src_.substr(0, current_src_.rfind("/") + 1);
  WaitOnImageAttach(model, *loader, url_prefix, callback);
  WaitOnFontAttach(model, *loader, url_prefix, callback);
}

void CompositionFetcher::WaitOnImageAttach(
    CompositionModel& model, canvas::ResourceLoader& loader,
    const std::string& url_prefix, const std::function<void()>& callback) {
  std::weak_ptr<CompositionFetcher> weak_this = shared_from_this();
  for (auto& image : model.GetImages()) {
    image.second->LoadBitmapBy(
        loader, url_prefix, polyfill_map_,
        [image, weak_this, callback](std::unique_ptr<canvas::Bitmap> bitmap,
                                     bool success) mutable {
          std::shared_ptr<CompositionFetcher> fetcher = weak_this.lock();
          if (!fetcher) {
            return;
          }
          fetcher->waiting_image_count_ -= 1;

          if (success && bitmap) {
            image.second->AttachBitmapDirectly(std::move(bitmap));
          }

          if (fetcher->IsAssetReady()) {
            fetcher->Record(ParseRecord::Stage::kLoadAssetEnd);
            callback();
          }
        });
  }
}

void CompositionFetcher::WaitOnFontAttach(
    CompositionModel& model, canvas::ResourceLoader& loader,
    const std::string& url_prefix, const std::function<void()>& callback) {
  std::weak_ptr<CompositionFetcher> weak_this = shared_from_this();
  for (auto& font : model.GetFonts()) {
    font.second->LoadFontBy(
        loader, url_prefix,
        [font, weak_this, callback](std::unique_ptr<canvas::RawData> raw_data,
                                    bool success) mutable {
          std::shared_ptr<CompositionFetcher> fetcher = weak_this.lock();
          if (!fetcher) {
            return;
          }
          fetcher->waiting_font_count_ -= 1;

          if (success && raw_data) {
            font.second->AttachRawDataDirectly(std::move(raw_data));
          }

          if (fetcher->IsAssetReady()) {
            fetcher->Record(ParseRecord::Stage::kLoadAssetEnd);
            callback();
          }
        });
  }
}

bool CompositionFetcher::IsAssetReady() {
  return waiting_image_count_ <= 0 && waiting_font_count_ <= 0;
}

void CompositionFetcher::Record(ParseRecord::Stage stage) {
  std::shared_ptr<AnimaXElement> element = element_.lock();
  if (element) {
    element->GetRecord().Record(stage);
  }
}

}  // namespace animax
}  // namespace lynx
