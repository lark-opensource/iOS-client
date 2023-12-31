// Copyright 2019 The Lynx Authors. All rights reserved.

#include "tasm/dynamic_component/dynamic_component_loader.h"

#include <utility>

#include "base/perf_collector.h"
#include "base/trace_event/trace_event.h"
#ifdef OS_ANDROID
#include "jsbridge/jscache/js_cache_manager_facade.h"
#endif
#include "tasm/binary_decoder/lynx_binary_reader.h"

namespace lynx {
namespace tasm {

namespace {
constexpr char kFormatErrorMessageBegin[] =
    "Load dynamic component failed, the url is ";
constexpr char kFormatErrorMessageJoiner[] = ", and the error message is ";
constexpr char kEmptyBinaryErrorMessage[] = "template binary is empty";

std::string ConstructErrorMessage(const std::string& url,
                                  const std::string& error_info) {
  std::string error_message = kFormatErrorMessageBegin;
  error_message.append(url);
  error_message.append(kFormatErrorMessageJoiner);
  error_message.append(error_info);
  return error_message;
}
}  // namespace

void DynamicComponentLoader::StartRecordRequireTime(const std::string& url,
                                                    int trace_id) {
  base::PerfCollector::GetInstance().StartRecordDynamicComponentPerf(
      trace_id, url,
      base::PerfCollector::DynamicComponentPerfTag::
          DYNAMIC_COMPONENT_REQUIRE_TIME);
}

void DynamicComponentLoader::LoadComponent(const std::string& url,
                                           std::vector<uint8_t> binary,
                                           bool sync) {
  if (engine_actor_ == nullptr) {
    return;
  }
  engine_actor_->Act(
      [url, binary = std::move(binary), sync](auto& engine) mutable {
        return engine->LoadComponent(url, std::move(binary), sync);
      });
}

void DynamicComponentLoader::Callback::HandleError(
    const std::optional<std::string>& error) {
  if (error) {
    error_code_ = LYNX_ERROR_CODE_DYNAMIC_COMPONENT_LOAD_FAIL;
    error_msg_ = ConstructErrorMessage(url_, *error);
  } else if (data_.empty()) {
    error_code_ = LYNX_ERROR_CODE_DYNAMIC_COMPONENT_FILE_EMPTY;
    error_msg_ = ConstructErrorMessage(url_, kEmptyBinaryErrorMessage);
  }
}

void DynamicComponentLoader::DidLoadComponent(const Callback& callback) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY,
              LYNX_TRACE_DYNAMIC_COMPONENT_DID_LOAD_COMPONENT, "url",
              callback.url_);

  base::PerfCollector::GetInstance().EndRecordDynamicComponentPerf(
      callback.trace_id_, callback.url_,
      base::PerfCollector::DynamicComponentPerfTag::
          DYNAMIC_COMPONENT_REQUIRE_TIME);

  const bool is_sync = SyncRequiring(callback.url_);

  if (callback.Success()) {
    LoadComponent(callback.url_, std::move(callback.data_), is_sync);
    return;
  }

  ReportErrorInner(callback.error_code_, callback.error_msg_);

  TemplateAssembler::TriggerDynamicComponentEvent(
      RadonDynamicComponent::ConstructErrMsg(
          callback.url_, callback.error_code_, callback.error_msg_, is_sync),
      is_sync, callback.component_,
      [self = this, &url = callback.url_](const lepus::Value& msg) {
        self->SendDynamicComponentEvent(url, msg);
      });
}

void DynamicComponentLoader::SendDynamicComponentEvent(
    const std::string& url, const lepus::Value& err) {
  if (engine_actor_ != nullptr) {
    engine_actor_->Act([url, err, self = this](auto& engine) {
      return engine->SendDynamicComponentEvent(url, err,
                                               self->GetRequireList(url));
    });
  }
}

bool DynamicComponentLoader::RequireTemplateCollected(
    RadonDynamicComponent* dynamic_component, const std::string& url,
    int trace_id) {
  // The return value indicates whether a request was actually sent.
  if (require_map_.find(url) == require_map_.end()) {
    this->RequireTemplate(dynamic_component, url, trace_id);
    return true;
  } else {
    return false;
  }
}

void DynamicComponentLoader::MarkNeedLoadComponent(
    RadonDynamicComponent* dynamic_component, const std::string& url) {
  require_map_[url].emplace_back(dynamic_component->Uid());
}

std::vector<uint32_t> DynamicComponentLoader::GetRequireList(
    const std::string& url) {
  auto map_finder = require_map_.find(url);
  auto require_id_list = std::move(map_finder->second);
  require_map_.erase(map_finder);
  return require_id_list;
}

/**
 * This method should be implemented at the platform layer
 * and callback DynamicComponentLoader::DidPreloadTemplate
 */
void DynamicComponentLoader::PreloadTemplates(
    const std::vector<std::string>& urls) {
  LOGW("DynamicComponentLoader::PreloadTemplates implement missing");
}

void DynamicComponentLoader::DidPreloadTemplate(const std::string& url,
                                                std::vector<uint8_t>&& binary) {
  TRACE_EVENT(LYNX_TRACE_CATEGORY, LYNX_TRACE_DYNAMIC_COMPONENT_DID_PRELOAD,
              "url", url);
  auto reader = LynxBinaryReader{
      std::make_unique<lepus::ByteArrayInputStream>(std::move(binary))};
  reader.SetIsCard(false);
  if (!reader.Decode()) {
    LOGE("DynamicComponentLoader::DidPreloadTemplate decode failed, url:"
         << url);
    return;
  }

  auto bundle = reader.GetTemplateBundle();

#ifdef OS_ANDROID
  // TODO(zhoupeng): Currently, there is no easy way to get JsEngineType, so
  // QUICK_JS is used by default. Fix it later.
  lynx::piper::cache::JsCacheManagerFacade::PostCacheGenerationTask(
      bundle, url, lynx::piper::cache::JsEngineType::QUICK_JS);
#endif

  if (engine_actor_) {
    engine_actor_->ActAsync(
        [url, bundle = std::move(bundle)](auto& engine) mutable {
          engine->InsertLynxTemplateBundle(url, std::move(bundle));
        });
  }
}

bool DynamicComponentLoader::SyncRequiring(const std::string& url) {
  // running on TASM thread and not in require_map_
  return engine_actor_ != nullptr && engine_actor_->CanRunNow() &&
         require_map_.count(url) == 0;
}

}  // namespace tasm
}  // namespace lynx
