// Copyright 2020 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_tracing_agent.h"

#include <fstream>
#include <memory>

#include "agent/devtool_agent_base.h"
#include "base/file_stream.h"

namespace lynxdev {
namespace devtool {

#if LYNX_ENABLE_TRACING
constexpr int kDefaultBufferSize = 20 * 1024;  // 20M
constexpr int kDefaultShmemSize = 1024;        // 1M
InspectorTracingAgent::InspectorTracingAgent() : tracing_session_id_(-1) {
#else
InspectorTracingAgent::InspectorTracingAgent() {
#endif
  functions_map_["Tracing.start"] = &InspectorTracingAgent::Start;
  functions_map_["Tracing.end"] = &InspectorTracingAgent::End;
  functions_map_["Tracing.getCategories"] =
      &InspectorTracingAgent::GetCategories;
  functions_map_["Tracing.recordClockSyncMarker"] =
      &InspectorTracingAgent::RecordClockSyncMarker;
  functions_map_["Tracing.requestMemoryDump"] =
      &InspectorTracingAgent::RequestMemoryDump;
}

InspectorTracingAgent::~InspectorTracingAgent() = default;

void InspectorTracingAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  std::string method = message["method"].asString();
  auto iter = functions_map_.find(method);
  if (iter == functions_map_.end() || devtool_agent == nullptr) {
    Json::Value res;
    res["error"]["code"] = kLynxInspectorErrorCode;
    res["error"]["message"] = "Not implemented: " + method;
    res["id"] = message["id"].asInt64();
    devtool_agent->SendResponseAsync(res);
  } else {
    (this->*(iter->second))(
        std::dynamic_pointer_cast<DevToolAgentBase>(devtool_agent), message);
  }
}

void InspectorTracingAgent::GetCategories(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {}

void InspectorTracingAgent::Start(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
#if LYNX_ENABLE_TRACING
  LOGI("start tracing");
  if (tracing_session_id_ > 0) {
    devtool_agent->ResponseError(id, "Tracing already started");
    return;
  }

  auto config = std::make_shared<lynx::base::tracing::TraceConfig>();
  const auto& params = message["params"];
  if (params.isMember("perfettoConfig")) {
    config->perfetto_config = message["perfettoConfig"].asString();
  } else if (params.isMember("traceConfig")) {
    const auto& trace_config = params["traceConfig"];
    const auto to_vector = [](const Json::Value& array,
                              std::vector<std::string>& result) {
      for (const auto& e : array) {
        result.push_back(e.asString());
      }
      return result;
    };
    to_vector(trace_config["includedCategories"], config->included_categories);
    to_vector(trace_config["excludedCategories"], config->excluded_categories);
    config->enable_systrace = trace_config["enableSystrace"].asBool();
    config->buffer_size = trace_config.isMember("bufferSize")
                              ? trace_config["bufferSize"].asInt()
                              : kDefaultBufferSize;
    config->shmem_size = trace_config.isMember("shmemSize")
                             ? trace_config["shmemSize"].asInt()
                             : kDefaultShmemSize;
    if (params.isMember("transferMode")) {
      const auto& transfer_mode = params["transferMode"];
      if (transfer_mode == "ReportEvents") {
        config->transfer_mode = lynx::base::tracing::TraceConfig::REPORT_EVENTS;
      } else {
        config->transfer_mode =
            lynx::base::tracing::TraceConfig::RETURN_AS_STREAM;
      }
    }
    if (trace_config.isMember("recordMod")) {
      const auto& record_mod = trace_config["recordMod"];
      if (record_mod == "recordContinuously") {
        config->record_mode =
            lynx::base::tracing::TraceConfig::RECORD_CONTINUOUSLY;
        config->transfer_mode =
            lynx::base::tracing::TraceConfig::RETURN_AS_STREAM;
      }
    }
  } else {
    config->excluded_categories = {"*"};
  }

  auto controller = devtool_agent->GetTraceController();
  if (controller == nullptr) {
    devtool_agent->ResponseError(id, "Failed to get trace controller");
    return;
  }

  controller->AddTracePlugin(devtool_agent->GetFPSTracePlugin());
  controller->AddTracePlugin(devtool_agent->GetInstanceTracePlugin());
  if (std::find(config->included_categories.begin(),
                config->included_categories.end(),
                LYNX_TRACE_CATEGORY_SCREENSHOTS) !=
      config->included_categories.end()) {
    controller->AddTracePlugin(devtool_agent->GetFrameViewTracePlugin());
  }
  tracing_session_id_ = controller->StartTracing(config);
  if (tracing_session_id_ > 0) {
    controller->AddCompleteCallback(
        tracing_session_id_, [config, devtool_agent]() {
          Json::Value msg;
          msg["method"] = "Tracing.tracingComplete";
          if (config->transfer_mode ==
              lynx::base::tracing::TraceConfig::RETURN_AS_STREAM) {
            int stream_handle = FileStream::Open(config->file_path);
            msg["params"]["dataLossOccurred"] = (stream_handle <= 0);
            msg["params"]["stream"] = std::to_string(stream_handle);
            msg["params"]["traceFormat"] = "proto";
            msg["params"]["streamCompression"] = "none";
          } else {
            msg["params"]["dataLossOccurred"] = false;
          }
          devtool_agent->SendResponseAsync(msg);
        });

    controller->AddEventsCallback(
        tracing_session_id_, [devtool_agent](const std::vector<char>& pending) {
          constexpr const char msg_header[] =
              "{ \"method\": \"Tracing.dataCollected\", \"params\": { "
              "\"value\": \"";
          constexpr const char msg_tail[] = "\" } }";
          constexpr const size_t msg_header_len = sizeof(msg_header) - 1;
          constexpr const size_t msg_tail_len = sizeof(msg_tail) - 1;

          auto encode_length = modp_b64_encode_len(pending.size());
          std::unique_ptr<char[]> buf = std::make_unique<char[]>(
              encode_length + msg_header_len + msg_tail_len + 1);
          char* p = buf.get();
          memcpy(p, msg_header, msg_header_len);
          p += msg_header_len;
          size_t offset = modp_b64_encode(p, &pending[0], pending.size());
          p += offset;
          memcpy(p, msg_tail, msg_tail_len);
          p += msg_tail_len;
          p[0] = '\0';
          devtool_agent->SendResponse(buf.get());
        });
    Json::Value res;
    res["result"] = Json::Value(Json::ValueType::objectValue);
    res["id"] = id;
    devtool_agent->SendResponseAsync(res);
  } else {
    devtool_agent->ResponseError(id, "Failed to start tracing");
  }
#else
  devtool_agent->ResponseError(id, "Tracing not enabled");
#endif
}

void InspectorTracingAgent::End(std::shared_ptr<DevToolAgentBase> devtool_agent,
                                const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt64());
#if LYNX_ENABLE_TRACING
  LOGI("End tracing");
  if (tracing_session_id_ <= 0) {
    devtool_agent->ResponseError(id, "Tracing is not started");
    return;
  }
  auto controller = devtool_agent->GetTraceController();
  if (controller == nullptr) {
    devtool_agent->ResponseError(id, "Failed to get trace controller");
    return;
  }
  devtool_agent->ResponseOK(static_cast<int>(message["id"].asInt64()));
  controller->StopTracing(tracing_session_id_);
  //  controller->RemoveCompleteCallbacks(tracing_session_id_);
  tracing_session_id_ = -1;
#else
  devtool_agent->ResponseError(id, "Tracing not enabled");
#endif
}

void InspectorTracingAgent::RecordClockSyncMarker(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  int id = static_cast<int>(message["id"].asInt());
#if LYNX_ENABLE_TRACING
  if (tracing_session_id_ <= 0) {
    devtool_agent->ResponseError(id, "Tracing is not started");
  }
  auto controller = devtool_agent->GetTraceController();
  if (controller == nullptr) {
    devtool_agent->ResponseError(id, "Failed to get trace controller");
    return;
  }
  controller->RecordClockSyncMarker(message["params"]["syncId"].asString());
  devtool_agent->ResponseOK(id);
#else
  devtool_agent->ResponseError(id, "Tracing not enabled");
#endif
}

void InspectorTracingAgent::RequestMemoryDump(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {}

}  // namespace devtool
}  // namespace lynxdev
