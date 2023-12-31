// Copyright 2023 The Lynx Authors. All rights reserved.

#ifndef ANIMAX_RESOURCE_COMPOSITION_FETCHER_H_
#define ANIMAX_RESOURCE_COMPOSITION_FETCHER_H_

#include <memory>
#include <string>
#include <unordered_map>

#include "animax/base/performance_record.h"
#include "animax/model/composition_model.h"
#include "canvas/canvas_app.h"
#include "canvas/platform/resource_loader.h"

namespace lynx {
namespace animax {

class AnimaXElement;

class CompositionFetcher
    : public std::enable_shared_from_this<CompositionFetcher> {
 public:
  using CompositionCallback =
      std::function<void(std::shared_ptr<CompositionModel>)>;
  using DataCallback = std::function<void(
      std::unique_ptr<lynx::canvas::RawData>, const std::string&)>;

  static constexpr const char* kJson = ".json";

  CompositionFetcher(const std::weak_ptr<AnimaXElement>& element,
                     const std::weak_ptr<lynx::canvas::CanvasApp>& canvas_app,
                     float scale);
  ~CompositionFetcher() = default;

  /**
   * Request animation format resource, and return raw data by callback
   * @param src      the url string of resource file
   * @param callback callback when the resource file is ready or some errors
   * occur. If resource is ready, the raw data is nonnull and the error message
   * is empty, otherwise the raw data is null and the error message is not empty
   */
  void RequestSource(const std::string& src, const DataCallback& callback);

  /**
   * Parse json data, and return composition model by callback
   * @param json     json file beginning address
   * @param length   json file length
   * @param callback callback with resolved composition model
   */
  void ParseJson(const char* json, size_t length,
                 const CompositionCallback& callback);

  /**
   * Set custom image and font path by polyfill map
   * @param polyfill a map, keys are "id" in "assert", values are images url
   */
  void SetSrcPolyfill(
      const std::unordered_map<std::string, std::string>& polyfill);

 private:
  /**
   * Request animation json format data and return
   * @param src
   * @param callback
   */
  void RequestJson(const std::string& src, const DataCallback& callback);

  /**
   * Load data by loader, called from RequestJson
   * @param src
   * @param loader
   * @param callback
   */
  void LoadJson(const std::string& src, canvas::ResourceLoader& loader,
                const DataCallback& callback);

  /**
   * Wait on image and font asset to be attached on composition model
   * @param model
   * @param callback
   */
  void WaitOnAssetAttach(CompositionModel& model,
                         const std::function<void()>& callback);

  /**
   * Wait on image to be attached on composition model
   * @param model
   * @param loader
   * @param url_prefix
   * @param callback
   */
  void WaitOnImageAttach(CompositionModel& model,
                         canvas::ResourceLoader& loader,
                         const std::string& url_prefix,
                         const std::function<void()>& callback);

  /**
   * Wait on font to be attached on composition model
   * @param model
   * @param loader
   * @param url_prefix
   * @param callback
   */
  void WaitOnFontAttach(CompositionModel& model, canvas::ResourceLoader& loader,
                        const std::string& url_prefix,
                        const std::function<void()>& callback);

  /**
   * Distinguish the asset has ready or not on this fetcher
   * @return
   */
  bool IsAssetReady();

  /**
   * Record the parse stage into performance record
   * @param stage
   */
  void Record(ParseRecord::Stage stage);

  std::weak_ptr<AnimaXElement> element_;
  std::weak_ptr<lynx::canvas::CanvasApp> canvas_app_;

  std::string current_src_;

  std::atomic<int32_t> waiting_image_count_ = 0;
  std::atomic<int32_t> waiting_font_count_ = 0;

  float scale_ = 1;

  std::unordered_map<std::string, std::string> polyfill_map_;
};

}  // namespace animax
}  // namespace lynx

#endif  // ANIMAX_RESOURCE_COMPOSITION_FETCHER_H_
