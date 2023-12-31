// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_DYNAMIC_COMPONENT_DYNAMIC_COMPONENT_LOADER_H_
#define LYNX_TASM_DYNAMIC_COMPONENT_DYNAMIC_COMPONENT_LOADER_H_

#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "shell/lynx_actor.h"
#include "shell/lynx_engine.h"
#include "tasm/radon/radon_dynamic_component.h"

namespace lynx {
namespace tasm {

class DynamicComponentLoader
    : public std::enable_shared_from_this<DynamicComponentLoader> {
  using RequireMap = std::unordered_map<std::string, std::vector<uint32_t>>;

 public:
  class Callback {
   public:
    Callback(std::string url, std::vector<uint8_t> data,
             const std::optional<std::string>& error,
             RadonDynamicComponent* component, int trace_id)
        : url_(std::move(url)),
          data_(std::move(data)),
          component_(component),
          trace_id_(trace_id) {
      HandleError(error);
    }
    Callback(const Callback&) = delete;
    Callback& operator=(const Callback&) = delete;
    Callback(Callback&&) = delete;
    Callback& operator=(Callback&&) = delete;
    ~Callback() = default;

    bool Success() const { return LYNX_ERROR_CODE_SUCCESS == error_code_; }

   private:
    void HandleError(const std::optional<std::string>& error);

    friend class DynamicComponentLoader;
    std::string url_;
    mutable std::vector<uint8_t> data_;
    RadonDynamicComponent* component_{nullptr};
    int trace_id_{0};
    ErrCode error_code_{LYNX_ERROR_CODE_SUCCESS};
    std::string error_msg_{};
  };

  class RequireScope {
   public:
    RequireScope(const std::shared_ptr<DynamicComponentLoader>& loader,
                 RadonDynamicComponent* component)
        : loader_(loader.get()) {
      loader_->requiring_component_ = component;
    }
    ~RequireScope() { loader_->requiring_component_ = nullptr; }

    RequireScope(const RequireScope&) = delete;
    RequireScope& operator=(const RequireScope&) = delete;
    RequireScope(RequireScope&&) = delete;
    RequireScope& operator=(RequireScope&&) = delete;

   private:
    DynamicComponentLoader* loader_{nullptr};
  };

 public:
  DynamicComponentLoader() : engine_actor_(nullptr) {}
  virtual ~DynamicComponentLoader() = default;
  inline void SetEngineActor(
      std::shared_ptr<shell::LynxActor<shell::LynxEngine>> actor) {
    engine_actor_ = actor;
  }

  void LoadComponent(const std::string& url, std::vector<uint8_t> binary,
                     bool sync);
  void SendDynamicComponentEvent(const std::string& url,
                                 const lepus::Value& err);
  virtual void RequireTemplate(RadonDynamicComponent* dynamic_component,
                               const std::string& url, int trace_id) = 0;

  // TODO(zhoupeng): Use DidLoadComponent in renderkit and then make
  // SendDynamicComponentEvent and SyncRequiring private
  void DidLoadComponent(const Callback& callback);

  bool RequireTemplateCollected(RadonDynamicComponent* dynamic_component,
                                const std::string& url, int trace_id);

  void MarkNeedLoadComponent(RadonDynamicComponent* dynamic_component,
                             const std::string& url);

  std::vector<uint32_t> GetRequireList(const std::string& url);

  virtual void SetEnableLynxResourceService(bool enable) {}

  virtual void PreloadTemplates(const std::vector<std::string>& urls);

  void DidPreloadTemplate(const std::string& url,
                          std::vector<uint8_t>&& binary);

  // is being required synchronously
  bool SyncRequiring(const std::string& url);

  inline RadonDynamicComponent* GetRequiringComponent() const {
    return requiring_component_;
  }

 protected:
  virtual void ReportErrorInner(ErrCode code, const std::string& msg){};

  void StartRecordRequireTime(const std::string& url, int trace_id);

 private:
  std::shared_ptr<shell::LynxActor<shell::LynxEngine>> engine_actor_;
  RequireMap require_map_;

  friend class RequireScope;
  RadonDynamicComponent* requiring_component_{nullptr};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_DYNAMIC_COMPONENT_DYNAMIC_COMPONENT_LOADER_H_
