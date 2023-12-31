// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/quickjs/inspector_client_quickjs_impl.h"

#include <map>
#include <memory>

#include "base/json/json_util.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_java_script_debugger.h"
#include "jsbridge/js_debug/inspector_runtime_manager.h"
#include "jsbridge/js_debug/quickjs/debugger/quickjs_debugger.h"
#include "jsbridge/js_debug/script_manager.h"
#include "jsbridge/jsi_executor.h"
#include "jsbridge/quickjs/quickjs_runtime.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "jsbridge/js_debug/lepusng/interface.h"
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace lynx {
namespace devtool {
static int cur_group_id_ = 1;

QJSChannelImpl::QJSChannelImpl(lepus_inspector::QJSInspector *inspector,
                               int view_id, const std::string &group_id)
    : view_id_(view_id), group_id_(group_id) {
  if (inspector != nullptr) {
    session_ = inspector->connect(group_id_, this, "", view_id_);
  }
}

void QJSChannelImpl::sendResponse(int call_id, const std::string &message) {
  SendResponseToClient(message, view_id_);
}

void QJSChannelImpl::sendNotification(const std::string &message) {
  SendResponseToClient(message, view_id_);
}

InspectorClientQuickJSImpl::InspectorClientQuickJSImpl(ClientType type)
    : InspectorClientQuickJSBase(type) {}

InspectorClientQuickJSImpl::~InspectorClientQuickJSImpl() = default;

void InspectorClientQuickJSImpl::InsertJSDebugger(
    const std::shared_ptr<InspectorJavaScriptDebugger> &debugger, int view_id,
    const std::string &group_id) {
  LOGI("js debug: InspectorClientQuickJSImpl::InsertJSDebugger, this: "
       << this << ", debugger: " << debugger << ", view_id: " << view_id
       << ", group_id: " << group_id << ", client type: " << type_);
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) {
    std::string group = MapGroupId(group_id);
    view_id_to_bundle_[view_id] =
        QJSDebugBundle{view_id,
                       kDefaultViewID,
                       group,
                       group_id == kSingleGroupID,
                       false,
                       debugger,
                       nullptr,
                       nullptr,
                       std::weak_ptr<piper::QuickjsContextWrapper>()};
    InsertViewIdToGroup(view_id, group);
  }
  AddScriptManager(view_id);
}

void InspectorClientQuickJSImpl::RemoveJSDebugger(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    LOGI("js debug: InspectorClientQuickJSImpl::RemoveJSDebugger, view_id"
         << view_id);
    RemoveViewIdFromGroup(view_id);
    view_id_to_bundle_.erase(it);
  }
}

void InspectorClientQuickJSImpl::SetViewDestroyed(bool destroyed, int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.view_destroyed_ = destroyed;
  }
}

void InspectorClientQuickJSImpl::SetJSRuntime(
    const std::shared_ptr<piper::Runtime> &runtime, int view_id) {
  auto qjs_runtime = std::static_pointer_cast<piper::QuickjsRuntime>(runtime);
  qjs_runtime->SetDebugViewId(view_id);
  auto qjs_vm = qjs_runtime->getJSRuntime();
  auto qjs_context = std::static_pointer_cast<piper::QuickjsContextWrapper>(
      qjs_runtime->getSharedContext());
  LOGI("js debug: vm: " << qjs_vm << ", context: " << qjs_context
                        << ", view_id: " << view_id);

  SetQuickjsContext(view_id, qjs_context);
  CreateQuickjsDebugger(qjs_context);
  InsertRuntimeId(runtime->getRuntimeId(), view_id);
  CreateInspector(view_id, qjs_context.get());
  ConnectFrontend(view_id);
  RegisterSharedContextReleaseCallback(view_id);
  CreateWorkerTarget(view_id);
}

void InspectorClientQuickJSImpl::ConnectFrontend(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    std::string group_id = it->second.group_id_;
    LOGI("js debug: InspectorClientQuickJSImpl::ConnectFrontend, old channel: "
         << view_id_to_bundle_[view_id].channel_ << ", view_id: " << view_id);
    view_id_to_bundle_[view_id].channel_ =
        std::static_pointer_cast<Channel>(std::make_shared<QJSChannelImpl>(
            GetInspectorByGroupId(group_id).get(), view_id, group_id));
    view_id_to_bundle_[view_id].channel_->SetClient(shared_from_this());
    LOGI("js debug: InspectorClientQuickJSImpl::ConnectFrontend, new channel: "
         << view_id_to_bundle_[view_id].channel_ << ", view_id: " << view_id);
  }
}

void InspectorClientQuickJSImpl::DisconnectFrontend(int view_id) {
  LOGI("js debug: InspectorClientQuickJSImpl::DisconnectFrontend, this: "
       << this << ", view_id: " << view_id);
  RemoveChannel(view_id);
  RemoveInspector(view_id);
  RemoveScript(view_id);
  RemoveConsoleMessage(view_id);
  RemoveRuntimeId(view_id);
  DestroyWorkerTarget(view_id);
}

void InspectorClientQuickJSImpl::DisconnectFrontendOfSharedJSContext(
    const std::string &group_str) {
  auto &view_set = GetViewIdInGroup(group_str);
  LOGI(
      "js debug: "
      "InspectorClientQuickJSImpl::DisconnectFrontendOfSharedJSContext, this: "
      << this << ", group_id: " << group_str
      << ", view count: " << view_set.size());
  if (view_set.size() < 1) {
    return;
  }
  RemoveInspector(*(view_set.begin()), true);
}

void InspectorClientQuickJSImpl::DispatchMessageFromFrontend(
    const std::string &message, int view_id) {
  rapidjson::Document map_message;
  if (!ParseStrToJson(map_message, message)) {
    return;
  }
  auto messages = GetMessagePostedToJSEngine(map_message, view_id);
  std::lock_guard<std::mutex> lock(message_queue_mutex_);
  for (const auto &m : messages) {
    message_queue_.emplace(m.first, m.second);
  }
  std::lock_guard<std::mutex> read_lock(mutex_);
  if (running_nested_loop_) {
    cv_.notify_all();
  } else {
    std::shared_ptr<InspectorClientQuickJSImpl> ref =
        std::static_pointer_cast<InspectorClientQuickJSImpl>(
            shared_from_this());
    RunOnJSThread(view_id, [ref]() { ref->FlushMessageQueue(); });
  }
}

void InspectorClientQuickJSImpl::SendResponse(const std::string &message,
                                              int view_id) {
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger != nullptr) {
    auto messages = GetMessagePosterToChrome(message, view_id);
    for (const auto &m : messages) {
      debugger->ResponseFromJSEngine(m);
    }
  }
}

void InspectorClientQuickJSImpl::runMessageLoopOnPause(
    const std::string &context_group_id) {
  if (running_nested_loop_) return;
  if (context_group_id == kDefaultWorkerGroupStr) {
    if (type_ != JsWorkerClient || view_id_to_bundle_.empty()) return;
    for (const auto &item : view_id_to_bundle_) {
      if (item.first > kErrorViewID && item.second.view_destroyed_) {
        return;
      }
    }
  } else {
    auto view_set = GetViewIdInGroup(context_group_id);
    if (view_set.empty()) {
      return;
    } else {
      int destroy_view_count = 0;
      for (const auto &item : view_set) {
        if (IsViewDestroyed(item)) destroy_view_count++;
      }
      if (destroy_view_count == static_cast<int>(view_set.size())) return;
    }
  }
  Pause();
}

void InspectorClientQuickJSImpl::SetQuickjsContext(
    int view_id, const std::shared_ptr<piper::QuickjsContextWrapper> &context) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.context_ = context;
  }
}

void InspectorClientQuickJSImpl::CreateQuickjsDebugger(
    const std::shared_ptr<piper::QuickjsContextWrapper> &context) {
  if (context == nullptr) return;
  context->PrepareQJSDebugger();
  if (context->GetDebugger() == nullptr) {
    std::shared_ptr<debug::QuickjsDebuggerBase> qjs_debugger =
        std::make_shared<debug::QuickjsDebugger>();
    context->SetDebugger(qjs_debugger);
    LOGI("js debug: CreateQuickjsDebugger, QuickjsContextWrapper: "
         << context << ", QuickjsDebugger: " << qjs_debugger);
  }
}

void InspectorClientQuickJSImpl::RegisterSharedContextReleaseCallback(
    int view_id) {
  static bool set_callback = false;
  auto it = view_id_to_bundle_.find(view_id);
  if (set_callback || it == view_id_to_bundle_.end() ||
      it->second.single_group_) {
    return;
  }
  runtime::InspectorRuntimeManager *runtime_manager =
      static_cast<runtime::InspectorRuntimeManager *>(
          lynx::piper::JSIExecutor::GetCurrentRuntimeManagerInstance(true));
  if (runtime_manager != nullptr) {
    runtime_manager->SetReleaseCallback(
        quickjs_debug,
        [inspector_client = shared_from_this()](const std::string &group_id) {
          inspector_client->DisconnectFrontendOfSharedJSContext(group_id);
        });
    set_callback = true;
  }
}

void InspectorClientQuickJSImpl::CreateInspector(
    int view_id, lynx::piper::QuickjsContextWrapper *context) {
  LOGI("js debug: InspectorClientQuickJSImpl::CreateInspector, context: "
       << context << ", view_id: " << view_id);
  auto iter = view_id_to_bundle_.find(view_id);
  if (iter == view_id_to_bundle_.end()) return;
  std::string group_id = iter->second.group_id_;

  auto it = group_to_qjs_inspector_.find(group_id);
  if (it == group_to_qjs_inspector_.end()) {
    group_to_qjs_inspector_[group_id] =
        lepus_inspector::QJSInspector::create(context, this, group_id);
    LOGI("js debug: create Inspector: " << group_to_qjs_inspector_[group_id]
                                        << ", group_id: " << group_id);
  }
}

const std::unique_ptr<lepus_inspector::QJSInspector> &
InspectorClientQuickJSImpl::GetInspectorByGroupId(const std::string &group_id) {
  auto it = group_to_qjs_inspector_.find(group_id);
  if (it != group_to_qjs_inspector_.end()) {
    return it->second;
  }
  return group_to_qjs_inspector_[kErrorGroupStr];
}

void InspectorClientQuickJSImpl::RemoveInspector(int view_id,
                                                 bool shared_context_release) {
  LOGI("js debug: InspectorClientQuickJSImpl::RemoveInspector, this: "
       << this << ", view_id: " << view_id);
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) {
    return;
  }
  auto group_id = it->second.group_id_;
  if (type_ == JsWorkerClient || it->second.single_group_ ||
      shared_context_release) {
    group_to_qjs_inspector_.erase(group_id);
    auto context = it->second.context_.lock();
    LOGI("js debug: removeInspector, context: " << context);
    if (context != nullptr) {
      SendMessageContextDestroyed(view_id,
                                  GetExecutionContextId(context->getContext()));
    }
  }
}

const std::weak_ptr<InspectorJavaScriptDebugger>
    &InspectorClientQuickJSImpl::GetJSDebuggerByViewId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.js_debugger_;
  }
  return view_id_to_bundle_[kErrorViewID].js_debugger_;
}

void InspectorClientQuickJSImpl::AddScriptManager(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end() && it->second.script_manager_ == nullptr) {
    it->second.script_manager_ = std::make_unique<ScriptManager>();
  }
}

const std::unique_ptr<ScriptManager>
    &InspectorClientQuickJSImpl::GetScriptManagerByViewId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.script_manager_;
  }
  return view_id_to_bundle_[kErrorViewID].script_manager_;
}

void InspectorClientQuickJSImpl::RemoveChannel(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    LOGI("js debug: reset channel: " << it->second.channel_
                                     << ", view_id: " << view_id);
    it->second.channel_.reset();
  }
}

const std::shared_ptr<Channel> &InspectorClientQuickJSImpl::GetChannelByViewId(
    int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.channel_;
  }
  return view_id_to_bundle_[kErrorViewID].channel_;
}

void InspectorClientQuickJSImpl::RemoveScript(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) return;
  auto context = it->second.context_.lock();
  if (context != nullptr) {
    std::string filename =
        kScriptUrlPrefix + std::to_string(view_id) + kScriptUrlAppService;
    DeleteScriptByURL(context->getContext(), filename.c_str());
  }
}

void InspectorClientQuickJSImpl::RemoveConsoleMessage(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) return;
  auto context = it->second.context_.lock();
  int runtime_id = it->second.runtime_id_;
  if (context != nullptr) {
    DeleteConsoleMessageWithRID(context->getContext(), runtime_id);
  }
}

std::string InspectorClientQuickJSImpl::MapGroupId(
    const std::string &group_id) {
  if (group_id == kSingleGroupID) {
    if (type_ == JsClient) {
      return kSingleGroupPrefix + std::to_string(cur_group_id_++);
    } else {
      return kDefaultWorkerGroupStr;
    }
  } else {
    return group_id;
  }
}

void InspectorClientQuickJSImpl::InsertViewIdToGroup(
    int view_id, const std::string &group_id) {
  if (group_id == kErrorGroupStr || group_id == kDefaultWorkerGroupStr) return;
  auto it = group_id_to_view_id_.find(group_id);
  if (it == group_id_to_view_id_.end()) {
    group_id_to_view_id_.insert({group_id, std::set<int>()});
  }
  group_id_to_view_id_[group_id].insert(view_id);
}

void InspectorClientQuickJSImpl::RemoveViewIdFromGroup(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) {
    return;
  }
  auto group_id = it->second.group_id_;
  auto group_it = group_id_to_view_id_.find(group_id);
  if (group_it != group_id_to_view_id_.end()) {
    group_it->second.erase(view_id);
    if (group_it->second.empty()) {
      group_id_to_view_id_.erase(group_it);
      if (GetInspectorByGroupId(group_id) != nullptr) {
        LOGI("js debug: QJSInspector hasn't been removed! view_id: "
             << view_id << ", group_id: " << group_id);
        RemoveInspector(view_id, true);
      }
    }
  }
}

const std::set<int> &InspectorClientQuickJSImpl::GetViewIdInGroup(
    const std::string &group_id) {
  auto it = group_id_to_view_id_.find(group_id);
  if (it != group_id_to_view_id_.end()) {
    return it->second;
  }
  return group_id_to_view_id_[kErrorGroupStr];
}

bool InspectorClientQuickJSImpl::IsViewEnabled(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    auto context = it->second.context_.lock();
    auto &enable_map = context->GetEnableMap();
    auto enable_map_it = enable_map.find(view_id);
    if (enable_map_it != enable_map.end()) {
      return enable_map_it->second[0];
    }
  }
  return false;
}

bool InspectorClientQuickJSImpl::IsViewDestroyed(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end() || it->second.view_destroyed_) {
    return true;
  }
  return false;
}

void InspectorClientQuickJSImpl::InsertRuntimeId(int runtime_id, int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.runtime_id_ = runtime_id;
  }
  runtime_id_to_view_id_[runtime_id] = view_id;
}

void InspectorClientQuickJSImpl::RemoveRuntimeId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    runtime_id_to_view_id_.erase(it->second.runtime_id_);
    it->second.runtime_id_ = kDefaultViewID;
  }
}

int InspectorClientQuickJSImpl::GetViewIdByRuntimeId(int runtime_id) {
  auto it = runtime_id_to_view_id_.find(runtime_id);
  if (it != runtime_id_to_view_id_.end()) {
    return it->second;
  }
  return kErrorViewID;
}

std::vector<std::string> InspectorClientQuickJSImpl::GetMessagePosterToChrome(
    const std::string &message, int view_id) {
  auto res = std::vector<std::string>();
  rapidjson::Document content;
  if (!ParseStrToJson(content, message)) {
    return res;
  }
  auto &script_manager = GetScriptManagerByViewId(view_id);

  if (content.HasMember(kKeyId) && content[kKeyId].GetInt() == 0) {
    return res;
  } else if (content.HasMember(kKeyMethod) &&
             strcmp(content[kKeyMethod].GetString(),
                    kEventRuntimeConsoleAPICalled) == 0) {
    if (content.HasMember(kKeyParams) &&
        content[kKeyParams].HasMember(kKeyRuntimeId)) {
      int runtime_id = content[kKeyParams][kKeyRuntimeId].GetInt();
      int console_view_id = GetViewIdByRuntimeId(runtime_id);
      content[kKeyParams].RemoveMember(kKeyRuntimeId);
      content[kKeyParams].AddMember(
          rapidjson::Value(kKeyConsoleId, content.GetAllocator()),
          rapidjson::Value(console_view_id), content.GetAllocator());
    }
  } else if (content.HasMember(kKeyId) && script_manager != nullptr) {
    script_manager->SetBreakpointId(content);
  }

  if (content.HasMember(kKeyResult) &&
      content[kKeyResult].HasMember(kKeyDebuggerId)) {
    content[kKeyResult].AddMember(
        rapidjson::Value(kKeyEngineType, content.GetAllocator()),
        rapidjson::Value(kKeyEngineQuickjs, content.GetAllocator()),
        content.GetAllocator());
  }
  if (content.HasMember(kKeyParams)) {
    content[kKeyParams].AddMember(
        rapidjson::Value(kKeyViewId, content.GetAllocator()),
        rapidjson::Value(view_id), content.GetAllocator());
  }

  AddWorkerSessionId(content);
  res.push_back(base::ToJson(content));
  return res;
}

std::vector<std::pair<int, std::string>>
InspectorClientQuickJSImpl::GetMessagePostedToJSEngine(
    rapidjson::Value &message, int view_id) {
  auto res = std::vector<std::pair<int, std::string>>();
  rapidjson::Document map_message;
  map_message.CopyFrom(message, map_message.GetAllocator());
  auto &script_manager = GetScriptManagerByViewId(view_id);
  RemoveWorkerSessionId(map_message);

  std::string method = map_message[kKeyMethod].GetString();
  if (method == kMethodDebuggerSetBreakpointsActive &&
      script_manager != nullptr) {
    bool active = map_message[kKeyParams][kKeyActive].GetBool();
    script_manager->SetBreakpointsActive(active);
  } else if (method == kMethodDebuggerSetBreakpointByUrl &&
             script_manager != nullptr) {
    script_manager->SetBreakpointDetail(map_message);
  } else if (method == kMethodDebuggerRemoveBreakpoint &&
             script_manager != nullptr) {
    script_manager->RemoveBreakpoint(
        map_message[kKeyParams][kKeyBreakpointId].GetString());
  } else if (method == kMethodDebuggerDisable) {
    if (HandleMessageDebuggerDisableFromFrontend(view_id, res)) {
      return res;
    }
  } else if (method == kMethodDebuggerEnable) {
    if (HandleMessageDebuggerEnableFromFrontend(
            view_id, base::ToJson(map_message), res)) {
      return res;
    }
  } else if (method == kMethodRuntimeEnable) {
    HandleMessageRuntimeEnableFromFrontend(view_id);
  } else if (method == kMethodProfilerStart) {
    profile_start_ = true;
  } else if (method == kMethodProfilerStop) {
    profile_start_ = false;
  }
  res.emplace_back(view_id, base::ToJson(map_message));
  return res;
}

void InspectorClientQuickJSImpl::SendMessageContextDestroyed(int view_id,
                                                             int context_id) {
  bool res = false;
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger != nullptr) {
    rapidjson::Document document(rapidjson::kObjectType);
    document.AddMember(rapidjson::Value(kKeyMethod, document.GetAllocator()),
                       rapidjson::Value(kEventRuntimeExecutionContextDestroyed,
                                        document.GetAllocator()),
                       document.GetAllocator());
    rapidjson::Document params(rapidjson::kObjectType);
    params.AddMember(
        rapidjson::Value(kKeyExecutionContextId, params.GetAllocator()),
        rapidjson::Value(context_id), params.GetAllocator());
    document.AddMember(rapidjson::Value(kKeyParams, document.GetAllocator()),
                       params, document.GetAllocator());
    res = debugger->ResponseFromJSEngine(base::ToJson(document));
  }
  if (!res) {
    std::lock_guard<std::mutex> lock(destroyed_context_queue_mutex_);
    destroyed_context_queue_.push(context_id);
  }
}

bool InspectorClientQuickJSImpl::HandleMessageDebuggerEnableFromFrontend(
    int view_id, const std::string &mes,
    std::vector<std::pair<int, std::string>> &mes_vec) {
  if (mes.find(kMethodDebuggerEnable) == std::string::npos ||
      need_disable_view_id_ == kErrorViewID) {
    return false;
  }
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) return false;
  auto disable_view_it = view_id_to_bundle_.find(need_disable_view_id_);
  if (disable_view_it == view_id_to_bundle_.end()) return false;
  std::string group_id = it->second.group_id_;
  std::string disable_group_id = disable_view_it->second.group_id_;
  if (disable_group_id != group_id || need_disable_view_id_ != view_id) {
    mes_vec.emplace_back(view_id, mes);
    mes_vec.emplace_back(need_disable_view_id_,
                         GetSimpleMessage(kMethodDebuggerDisable));
    need_disable_view_id_ = kErrorViewID;
    return true;
  }
  return false;
}

bool InspectorClientQuickJSImpl::HandleMessageDebuggerDisableFromFrontend(
    int view_id, std::vector<std::pair<int, std::string>> &mes_vec) {
  mes_vec.emplace_back(view_id, GetSimpleMessage(kMethodRuntimeDisable));
  if (!running_nested_loop_ || profile_start_) return false;
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end() && !it->second.single_group_) {
    auto group_id = it->second.group_id_;
    auto view_set = GetViewIdInGroup(group_id);
    for (const auto &id : view_set) {
      if (id != view_id && IsViewEnabled(id)) return false;
    }
    if (view_set.size() > 1) {
      need_disable_view_id_ = view_id;
      return true;
    }
  }
  return false;
}

void InspectorClientQuickJSImpl::HandleMessageRuntimeEnableFromFrontend(
    int view_id) {
  std::queue<int> que;
  {
    std::lock_guard<std::mutex> lock(destroyed_context_queue_mutex_);
    que.swap(destroyed_context_queue_);
  }
  while (!que.empty()) {
    auto context_id = que.front();
    SendMessageContextDestroyed(view_id, context_id);
    que.pop();
  }
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger != nullptr) {
    debugger->SetRuntimeEnableNeeded(true);
  }
}

void InspectorClientQuickJSImpl::CreateWorkerTarget(int view_id) {
  if (type_ == JsWorkerClient) {
    worker_target_id_ = kWorkerTargetIdPrefix + std::to_string(view_id);
    worker_session_id_ = kWorkerSessionIdPrefix + std::to_string(view_id);
    auto debugger = GetJSDebuggerByViewId(view_id).lock();
    if (debugger != nullptr) {
      debugger->ResponseFromJSEngine(
          GetMessageTargetCreated(worker_target_id_, kWorkerTargetTitle));
      debugger->ResponseFromJSEngine(GetMessageAttachedToTarget(
          worker_target_id_, worker_session_id_, kWorkerTargetTitle));
    }
  }
}

void InspectorClientQuickJSImpl::DestroyWorkerTarget(int view_id) {
  if (type_ == JsWorkerClient) {
    auto debugger = GetJSDebuggerByViewId(view_id).lock();
    if (debugger != nullptr) {
      debugger->ResponseFromJSEngine(
          GetMessageDetachFromTarget(worker_target_id_, worker_session_id_));
      debugger->ResponseFromJSEngine(
          GetMessageTargetDestroyed(worker_target_id_));
    }
    const std::unique_ptr<ScriptManager> &manager =
        GetScriptManagerByViewId(view_id);
    if (manager != nullptr) {
      manager->RemoveAllBreakpoints();
    }
  }
}

void InspectorClientQuickJSImpl::AddWorkerSessionId(
    rapidjson::Document &message) {
  if (type_ == JsWorkerClient) {
    message.AddMember(
        rapidjson::Value(kKeySessionId, message.GetAllocator()),
        rapidjson::Value(worker_session_id_, message.GetAllocator()),
        message.GetAllocator());
  }
}

void InspectorClientQuickJSImpl::RemoveWorkerSessionId(
    rapidjson::Value &message) {
  if (type_ != JsWorkerClient) return;
  if (message.HasMember(kKeySessionId)) {
    auto session_id = message[kKeySessionId].GetString();
    if (session_id != worker_session_id_) {
      LOGI(
          "js debug: worker session_id does not match! session_id of this "
          "worker: "
          << worker_session_id_ << ", session_id of message: " << session_id);
      return;
    }
    message.RemoveMember(kKeySessionId);
  }
}

void InspectorClientQuickJSImpl::RunOnJSThread(int view_id,
                                               base::closure closure) {
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger) {
    debugger->RunOnJSThread(std::move(closure), type_ == JsWorkerClient);
  }
}

}  // namespace devtool
}  // namespace lynx
