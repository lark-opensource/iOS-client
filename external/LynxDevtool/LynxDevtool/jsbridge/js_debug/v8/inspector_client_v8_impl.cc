// Copyright 2019 The Lynx Authors. All rights reserved.
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
#include "inspector_client_v8_impl.h"

#include <locale>

#include "Lynx/base/string/string_utils.h"
#include "base/compiler_specific.h"
#include "base/json/json_util.h"
#include "base/no_destructor.h"
#include "base/timer/time_utils.h"
#include "config/devtool_config.h"
#include "jsbridge/js_debug/debug_helper.h"
#include "jsbridge/js_debug/inspector_java_script_debugger.h"
#include "jsbridge/js_debug/inspector_runtime_manager.h"
#include "jsbridge/js_debug/script_manager.h"
#include "jsbridge/jsi_executor.h"
#include "jsbridge/v8/v8_helper.h"
#include "jsbridge/v8/v8_runtime.h"
#include "third_party/fml/make_copyable.h"
#include "third_party/fml/thread.h"

namespace {

template <class Facet>
class usable_facet : public Facet {
 public:
  using Facet::Facet;  // inherit constructors
  ~usable_facet() = default;
};
template <typename internT, typename externT, typename stateT>
using codecvt = usable_facet<std::codecvt<internT, externT, stateT>>;

std::string StringViewToUtf8(v8_inspector::StringView& view) {
  if (view.length() == 0) return "";
  if (view.is8Bit())
    return std::string(reinterpret_cast<const char*>(view.characters8()),
                       view.length());
  const uint16_t* source = view.characters16();
  const char16_t* ch = reinterpret_cast<const char16_t*>(source);
  std::u16string utf16(ch);
  std::string utf8_ret;
  lynx::base::ConvertUtf16StringToUtf8String(utf16, utf8_ret);
  return utf8_ret;
}

ALLOW_UNUSED_TYPE v8_inspector::StringView Utf8ToStringView(
    const std::string& message) {
  v8_inspector::StringView message_view(
      reinterpret_cast<const uint8_t*>(message.c_str()), message.size());
  return message_view;
}
}  // namespace

namespace lynx {

namespace devtool {

static int cur_group_id_ = 1;

ChannelImpl::ChannelImpl(v8_inspector::V8Inspector* inspector,
                         int view_id = kDefaultViewID,
                         int group_id = kDefaultGroupID)
    : view_id_(view_id), group_id_(group_id) {
#if V8_MAJOR_VERSION > 10 ||   \
    (V8_MAJOR_VERSION == 10 && \
     (V8_MINOR_VERSION > 3 ||  \
      V8_MINOR_VERSION == 3 && V8_BUILD_NUMBER >= 118))
  session_ = inspector->connect(group_id_, this, v8_inspector::StringView(),
                                v8_inspector::V8Inspector::kFullyTrusted);
#else
  session_ = inspector->connect(group_id_, this, v8_inspector::StringView());
#endif
}

void ChannelImpl::SetClient(const std::shared_ptr<InspectorClient>& sp) {
  client_wp_ = sp;
}

bool ChannelImpl::DispatchProtocolMessage(const std::string& message) {
#if OS_ANDROID
  v8_inspector::StringView message_view = Utf8ToStringView(message);
#else
  v8_inspector::StringView message_view(
      reinterpret_cast<const uint8_t*>(message.c_str()), message.size());
#endif
  if (session_ != nullptr) {
    session_->dispatchProtocolMessage(message_view);
    return true;
  }
  return false;
}

void ChannelImpl::SchedulePauseOnNextStatement(const std::string& reason) {
#if OS_ANDROID
  v8_inspector::StringView view = Utf8ToStringView(reason);
#else
  v8_inspector::StringView view(
      reinterpret_cast<const uint8_t*>(reason.c_str()), reason.size());
#endif
  if (session_ != nullptr) session_->schedulePauseOnNextStatement(view, view);
}

void ChannelImpl::CancelPauseOnNextStatement() {
  if (session_ != nullptr) {
    session_->cancelPauseOnNextStatement();
  }
}

void ChannelImpl::sendResponse(
    int callId, std::unique_ptr<v8_inspector::StringBuffer> message) {
  v8_inspector::StringView message_view = message->string();
  std::string str = StringViewToUtf8(message_view);

  auto sp = client_wp_.lock();
  if (sp != nullptr) {
    sp->SendResponse(str, view_id_);
  }
}

void ChannelImpl::sendNotification(
    std::unique_ptr<v8_inspector::StringBuffer> message) {
  v8_inspector::StringView message_view = message->string();
  std::string str = StringViewToUtf8(message_view);
  auto sp = client_wp_.lock();
  if (sp != nullptr) {
    sp->SendResponse(str, view_id_);
  }
}

InspectorClientV8Impl::InspectorClientV8Impl(ClientType type)
    : InspectorClient(type) {}

InspectorClientV8Impl::~InspectorClientV8Impl() = default;

void InspectorClientV8Impl::InsertJSDebugger(
    const std::shared_ptr<InspectorJavaScriptDebugger>& debugger, int view_id,
    const std::string& group_id) {
  LOGI("js debug: InspectorClientV8Impl::InsertJSDebugger, this: "
       << this << ", debugger: " << debugger << ", view_id: " << view_id
       << ", client type: " << type_);
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) {
    int group = MapGroupStrToNum(view_id, group_id);
    view_id_to_bundle_[view_id] = JsDebugBundle{
        view_id,
        kDefaultViewID,
        group,
        true,
        false,
        false,
        debugger,
        nullptr,
        nullptr,
        v8::Persistent<v8::Context,
                       v8::CopyablePersistentTraits<v8::Context>>(),
        std::set<int>()};
    if (group_id != kSingleGroupID) {
      view_id_to_bundle_[view_id].single_group_ = false;
    }
    if (view_id > 0) {
      InsertViewId(group, view_id);
    }
  }
  AddScriptManager(view_id);
}

void InspectorClientV8Impl::RemoveJSDebugger(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    int group_id = it->second.group_id_;
    LOGI("js debug: InspectorClientV8Impl::RemoveJSDebugger, view_id: "
         << view_id << ", group_id: " << group_id);
    SendMessageRemoveScripts(view_id);
    view_id_to_bundle_.erase(it);
    RemoveViewIdFromGroup(group_id, view_id);
    RemoveGroup(group_id);
    if (view_id == disable_view_id_) {
      disable_view_id_ = kErrorViewID;
    }
  }
}

void InspectorClientV8Impl::SetJSRuntime(
    const std::shared_ptr<piper::Runtime>& runtime, int view_id) {
  std::shared_ptr<piper::V8Runtime> v8runtime =
      std::static_pointer_cast<piper::V8Runtime>(runtime);
  piper::Scope scope(*v8runtime);
  v8runtime->SetDebugViewId(view_id);
  bool isSameIsolate = (isolate_ && isolate_ == v8runtime->getIsolate());
  LOGI("js debug: InspectorClientV8Impl::SetJSRuntime, isSameIsolate: "
       << isSameIsolate << ", view_id: " << view_id);
  isolate_ = v8runtime->getIsolate();
  InsertRuntimeId(v8runtime->getRuntimeId(), view_id);
  CreateV8Inspector(view_id);
  ConnectFrontend(view_id);
  ContextCreated(view_id, v8runtime->getContext());
  CreateWorkerTarget(view_id);
}

void InspectorClientV8Impl::SetViewDestroyed(bool destroyed, int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.view_destroyed_ = destroyed;
  }
}

void InspectorClientV8Impl::ConnectFrontend(int view_id) {
  const std::shared_ptr<ChannelImpl>& channel = AddChannel(view_id);
  if (channel != nullptr) {
    channel->SetClient(shared_from_this());
  }
}

void InspectorClientV8Impl::DisconnectFrontend(int view_id) {
  LOGI("js debug: InspectorClientV8Impl::DisconnectFrontend, this: "
       << this << ", view_id: " << view_id);
  InsertInvalidScriptId(view_id);
  RemoveChannel(view_id);
  ContextDestroyed(view_id);
  RemoveRuntimeId(view_id);
  DestroyWorkerTarget(view_id);
}

void InspectorClientV8Impl::DisconnectFrontendOfSharedJSContext(
    const std::string& group_str) {
  auto it = group_string_to_number_.find(group_str);
  if (it == group_string_to_number_.end()) {
    return;
  }
  auto view_set = GetViewIdInGroup(it->second);
  LOGI(
      "js debug: "
      "InspectorClientV8Impl::DisconnectFrontendOfSharedJSContext, this: "
      << this << ", group_id: " << group_str
      << ", view count: " << view_set.size());
  if (view_set.size() < 1) {
    return;
  }
  ContextDestroyed(*(view_set.begin()), true);
}

void InspectorClientV8Impl::SetBreakpointWhenReload(int view_id) {
  const std::unique_ptr<ScriptManager>& script_manager =
      GetScriptManagerByViewId(view_id);
  if (script_manager == nullptr) {
    return;
  }
  auto breakpoint = script_manager->GetBreakpoint();
  if (breakpoint.empty()) {
    return;
  }
  for (const auto& bp : breakpoint) {
    rapidjson::Document content(rapidjson::kObjectType);
    content.AddMember(rapidjson::Value(kKeyId, content.GetAllocator()),
                      rapidjson::Value(0), content.GetAllocator());
    content.AddMember(rapidjson::Value(kKeyMethod, content.GetAllocator()),
                      rapidjson::Value(kMethodDebuggerSetBreakpointByUrl,
                                       content.GetAllocator()),
                      content.GetAllocator());
    rapidjson::Document params(rapidjson::kObjectType);
    params.AddMember(
        rapidjson::Value(kKeyUrl, params.GetAllocator()),
        rapidjson::Value(bp.second.url_.c_str(), params.GetAllocator()),
        params.GetAllocator());
    params.AddMember(
        rapidjson::Value(kKeyCondition, params.GetAllocator()),
        rapidjson::Value(bp.second.condition_.c_str(), params.GetAllocator()),
        params.GetAllocator());
    params.AddMember(rapidjson::Value(kKeyLineNumber, params.GetAllocator()),
                     rapidjson::Value(bp.second.line_number_),
                     params.GetAllocator());
    params.AddMember(rapidjson::Value(kKeyColumnNumber, params.GetAllocator()),
                     rapidjson::Value(bp.second.column_number_),
                     params.GetAllocator());
    content.AddMember(rapidjson::Value(kKeyParams, content.GetAllocator()),
                      params, content.GetAllocator());
    DispatchMessageFromFrontendSync(base::ToJson(content), view_id);
  }
  auto active_mes =
      GetMessageSetBreakpointsActive(script_manager->GetBreakpointsActive(), 0);
  DispatchMessageFromFrontendSync(active_mes, view_id);
}

void InspectorClientV8Impl::DispatchMessageStop(int view_id) {
  const std::unique_ptr<ScriptManager>& script_manager =
      GetScriptManagerByViewId(view_id);
  if (script_manager != nullptr) {
    script_manager->ClearScriptId();
  }
  rapidjson::Document content(rapidjson::kObjectType);
  rapidjson::Document params(rapidjson::kObjectType);
  content.AddMember(rapidjson::Value(kKeyId, content.GetAllocator()),
                    rapidjson::Value(0), content.GetAllocator());
  content.AddMember(
      rapidjson::Value(kKeyMethod, content.GetAllocator()),
      rapidjson::Value(kMethodDebuggerSetSkipAllPauses, content.GetAllocator()),
      content.GetAllocator());
  params.AddMember(rapidjson::Value(kKeySkip, params.GetAllocator()),
                   rapidjson::Value(true), params.GetAllocator());
  content.AddMember(rapidjson::Value(kKeyParams, content.GetAllocator()),
                    params, content.GetAllocator());
  DispatchMessageFromFrontend(base::ToJson(content), view_id);
  if (!running_nested_loop_) return;
  content.RemoveMember(kKeyMethod);
  content.AddMember(
      rapidjson::Value(kKeyMethod, content.GetAllocator()),
      rapidjson::Value(kMethodDebuggerResume, content.GetAllocator()),
      content.GetAllocator());
  content.RemoveMember(kKeyParams);
  DispatchMessageFromFrontend(base::ToJson(content), view_id);
}

void InspectorClientV8Impl::DispatchMessageFromFrontend(
    const std::string& message, int view_id) {
  rapidjson::Document map_message;
  if (!ParseStrToJson(map_message, message)) {
    return;
  }
  auto messages = GetMessagePostedToJSEngine(map_message, view_id);
  std::lock_guard<std::mutex> lock(message_queue_mutex_);
  for (const auto& m : messages) {
    message_queue_.push(std::make_pair(m.first, m.second));
  }
  std::lock_guard<std::mutex> read_lock(mutex_);
  if (running_nested_loop_) {
    cv_.notify_all();
  } else {
    std::shared_ptr<InspectorClientV8Impl> ref =
        std::static_pointer_cast<InspectorClientV8Impl>(shared_from_this());
    RunOnJSThread(view_id, [ref]() { ref->FlushMessageQueue(); });
  }
}

void InspectorClientV8Impl::DispatchMessageFromFrontendSync(
    const std::string& message, int view_id) {
  const std::shared_ptr<ChannelImpl>& channel = GetChannelByViewId(view_id);
  if (channel != nullptr) {
#if V8_MAJOR_VERSION >= 9
    v8::Isolate::Scope scope(isolate_);
#endif
    bool res = channel->DispatchProtocolMessage(message);
    if (res) SetViewEnabled(message, view_id);
  }
}

void InspectorClientV8Impl::SendResponse(const std::string& message,
                                         int view_id) {
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger != nullptr) {
    auto messages = GetMessagePosterToChrome(message, view_id);
    for (const auto& m : messages) {
      debugger->ResponseFromJSEngine(m);
    }
  }
}

void InspectorClientV8Impl::SendMessageProfileEnabled(int view_id) {
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger != nullptr) {
    rapidjson::Document document(rapidjson::kObjectType);
    document.AddMember(
        rapidjson::Value(kKeyMethod, document.GetAllocator()),
        rapidjson::Value(kEventProfilerEnabled, document.GetAllocator()),
        document.GetAllocator());
    debugger->ResponseFromJSEngine(base::ToJson(document));
  }
}

void InspectorClientV8Impl::runMessageLoopOnPause(int context_group_id) {
  if (running_nested_loop_) return;
  if (context_group_id < 0 &&
      IsViewDestroyed(GetViewIdOfDefaultGroupId(context_group_id))) {
    return;
  } else if (context_group_id > 0) {
    auto view_set = GetViewIdInGroup(context_group_id);
    if (view_set.empty()) {
      return;
    } else if (view_set.size() == 1) {
      int view_id = *(view_set.begin());
      if (IsViewDestroyed(view_id)) {
        return;
      }
    }
  }
  Pause();
}

void InspectorClientV8Impl::quitMessageLoopOnPause() { QuitPause(); }

v8::Local<v8::Context> InspectorClientV8Impl::ensureDefaultContextInGroup(
    int contextGroupId) {
  auto it = view_id_to_bundle_.find(contextGroupId);
  if (it != view_id_to_bundle_.end()) {
    return it->second.context_.Get(isolate_);
  }
  return view_id_to_bundle_[kErrorViewID].context_.Get(isolate_);
}

double InspectorClientV8Impl::currentTimeMS() {
  return static_cast<double>(base::CurrentTimeMilliseconds());
}

void InspectorClientV8Impl::startRepeatingTimer(double interval,
                                                TimerCallback callback,
                                                void* data) {
  if (timer_ == nullptr) {
    timer_ = std::make_unique<base::TimedTaskManager>();
  }
  uint32_t task_id = timer_->SetInterval([callback, data]() { callback(data); },
                                         static_cast<int64_t>(interval * 1000));
  timed_task_ids_.emplace(data, task_id);
}

void InspectorClientV8Impl::cancelTimer(void* data) {
  if (timer_ == nullptr) {
    timer_ = std::make_unique<base::TimedTaskManager>();
  }
  auto iter = timed_task_ids_.find(data);
  if (iter != timed_task_ids_.end()) {
    timer_->StopTask(iter->second);
    timed_task_ids_.erase(iter);
  }
}

void InspectorClientV8Impl::CreateV8Inspector(int view_id) {
  LOGI("js debug: InspectorClientV8Impl::CreateV8Inspector, old inspector_: "
       << inspector_ << ", view_id: " << view_id);
  if (view_id > 0 && type_ == JsClient) {
    if (inspector_ == nullptr) {
      inspector_ = v8_inspector::V8Inspector::create(isolate_, this);
    }
  } else {
    inspector_ = v8_inspector::V8Inspector::create(isolate_, this);
  }
  LOGI("js debug: InspectorClientV8Impl::CreateV8Inspector, new inspector_: "
       << inspector_ << ", view_id: " << view_id);
}

void InspectorClientV8Impl::ContextCreated(int view_id,
                                           v8::Local<v8::Context> context) {
  view_id_to_bundle_[view_id].context_.Reset(isolate_, context);
  int group_id = view_id_to_bundle_[view_id].group_id_;
  if (GetContextCreated(group_id)) {
    return;
  }
  v8_inspector::V8ContextInfo info(context, group_id,
                                   v8_inspector::StringView());
  inspector_->contextCreated(info);
  SetContextCreated(group_id);
  LOGI("js debug: ContextCreated view_id: " << view_id
                                            << ", group_id: " << group_id);

  static bool set_callback = false;
  if (!set_callback && view_id > 0 &&
      !view_id_to_bundle_[view_id].single_group_) {
    runtime::InspectorRuntimeManager* runtime_manager =
        static_cast<runtime::InspectorRuntimeManager*>(
            lynx::piper::JSIExecutor::GetCurrentRuntimeManagerInstance(true));
    runtime_manager->SetReleaseCallback(
        v8_debug,
        [inspector_client = shared_from_this()](const std::string& group_str) {
          inspector_client->DisconnectFrontendOfSharedJSContext(group_str);
        });
    set_callback = true;
  }
}

void InspectorClientV8Impl::ContextDestroyed(int view_id,
                                             bool shared_context_release) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end()) {
    return;
  }
  LOGI("js debug: InspectorClientV8Impl::ContextDestroyed, context IsEmpty: "
       << it->second.context_.IsEmpty() << ", inspector: " << inspector_
       << ", view_id: " << view_id);
  int context_id = 0;
  if (isolate_ != nullptr && !it->second.context_.IsEmpty()) {
    ENTER_ISO_SCOPE(isolate_, it->second.context_);
    context_id = v8_inspector::V8ContextInfo::executionContextId(
        it->second.context_.Get(isolate_));
  }
  if (view_id < 0 || type_ == JsWorkerClient) {
    SendMessageContextDestroyed(view_id, context_id);
    inspector_.reset();
    it->second.context_.Reset();
  } else if (inspector_ != nullptr && !it->second.context_.IsEmpty()) {
    int group_id = it->second.group_id_;
    ENTER_ISO_SCOPE(isolate_, it->second.context_);
    if (it->second.single_group_ || shared_context_release) {
      LOGI("js debug: ContextDestroyed, group_id: "
           << group_id << ", isSingleGroup: " << it->second.single_group_
           << ", shared_context_release: " << shared_context_release);
      inspector_->contextDestroyed(it->second.context_.Get(isolate_));
      SendMessageContextDestroyed(view_id, context_id);
      inspector_->resetContextGroup(group_id);
      RemoveContextCreated(group_id);
      it->second.context_.Reset();
    }
  }
}

const std::weak_ptr<InspectorJavaScriptDebugger>&
InspectorClientV8Impl::GetJSDebuggerByViewId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.js_debugger_;
  }
  return view_id_to_bundle_[kErrorViewID].js_debugger_;
}

void InspectorClientV8Impl::AddScriptManager(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end() && it->second.script_manager_ == nullptr) {
    it->second.script_manager_ = std::make_unique<ScriptManager>();
  }
}

const std::unique_ptr<ScriptManager>&
InspectorClientV8Impl::GetScriptManagerByViewId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.script_manager_;
  }
  return view_id_to_bundle_[kErrorViewID].script_manager_;
}

const std::shared_ptr<ChannelImpl>& InspectorClientV8Impl::AddChannel(
    int view_id) {
  auto& it = view_id_to_bundle_.find(view_id)->second;
  LOGI("js debug: InspectorClientV8Impl::AddChannel, old channel: "
       << it.channel_ << ", view_id: " << view_id);
  if (view_id < 0 && type_ == JsClient) {
    it.channel_ = std::make_shared<ChannelImpl>(inspector_.get());
  } else {
    int group_id = view_id_to_bundle_[view_id].group_id_;
    it.channel_ =
        std::make_shared<ChannelImpl>(inspector_.get(), view_id, group_id);
  }
  LOGI("js debug: InspectorClientV8Impl::AddChannel, new channel: "
       << it.channel_ << ", view_id: " << view_id);
  return it.channel_;
}

void InspectorClientV8Impl::RemoveChannel(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    LOGI("js debug: InspectorClientV8Impl::RemoveChannel, channel: "
         << it->second.channel_ << ", view_id: " << view_id);
    it->second.channel_.reset();
  }
}

const std::shared_ptr<ChannelImpl>& InspectorClientV8Impl::GetChannelByViewId(
    int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.channel_;
  }
  return view_id_to_bundle_[kErrorViewID].channel_;
}

bool InspectorClientV8Impl::IsViewInSingleGroup(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.single_group_;
  }
  return true;
}

bool InspectorClientV8Impl::IsViewDestroyed(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end() || it->second.view_destroyed_) {
    return true;
  }
  return false;
}

bool InspectorClientV8Impl::IsScriptViewDestroyed(
    const std::string& script_url) {
  int view_id = GetScriptViewId(script_url);
  if (view_id != kErrorViewID) {
    return IsViewDestroyed(view_id);
  }
  return false;
}

int InspectorClientV8Impl::GetScriptViewId(const std::string& script_url) {
  std::string url = script_url;
  size_t pos = url.find(kScriptUrlPrefix);
  if (pos != std::string::npos) {
    url = url.substr(std::strlen(kScriptUrlPrefix));
    pos = url.find("/");
    if (pos != std::string::npos) {
      int view_id = std::stoi(url.substr(0, pos));
      return view_id;
    }
  }
  return kErrorViewID;
}

void InspectorClientV8Impl::InsertScriptId(int view_id, int script_id) {
  if (view_id == kErrorViewID || GetScriptIdInvalid(script_id)) {
    return;
  }
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end() || it->second.single_group_) {
    return;
  }
  auto& script_id_set = it->second.script_id_;
  script_id_set.insert(script_id);
}

void InspectorClientV8Impl::RemoveScriptId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.script_id_.clear();
  }
}

const std::set<int>& InspectorClientV8Impl::GetScriptId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.script_id_;
  }
  return view_id_to_bundle_[kErrorViewID].script_id_;
}

void InspectorClientV8Impl::InsertInvalidScriptId(int view_id) {
  if (view_id < 0 || IsViewInSingleGroup(view_id)) {
    return;
  }
  const std::set<int>& script_id_set = GetScriptId(view_id);
  for (const auto& id : script_id_set) {
    invalid_script_id_.insert(id);
  }
  RemoveScriptId(view_id);
}

bool InspectorClientV8Impl::GetScriptIdInvalid(int script_id) {
  auto it = invalid_script_id_.find(script_id);
  if (it == invalid_script_id_.end()) {
    return false;
  }
  return true;
}

int InspectorClientV8Impl::MapGroupStrToNum(int view_id,
                                            const std::string& group_string) {
  if (view_id < 0 && type_ == JsClient) {
    return kDefaultGroupID;
  } else if (group_string == kSingleGroupID) {
    if (type_ == JsClient) {
      return cur_group_id_++;
    } else {
      return kDefaultWorkerGroupID;
    }
  } else {
    auto it = group_string_to_number_.find(group_string);
    if (it == group_string_to_number_.end()) {
      int group_id = cur_group_id_++;
      group_string_to_number_[group_string] = group_id;
      group_number_to_string_[group_id] = group_string;
    }
    return group_string_to_number_[group_string];
  }
}

const std::string& InspectorClientV8Impl::MapGroupNumToStr(int group_id) {
  auto it = group_number_to_string_.find(group_id);
  if (it != group_number_to_string_.end()) {
    return it->second;
  }
  return group_number_to_string_[kErrorGroupID];
}

void InspectorClientV8Impl::RemoveGroup(int group_id) {
  int num = GetViewCountOfGroup(group_id);
  if (num <= 0) {
    std::string group_str = MapGroupNumToStr(group_id);
    group_number_to_string_.erase(group_id);
    group_string_to_number_.erase(group_str);
  }
}

void InspectorClientV8Impl::InsertViewId(int group_id, int view_id) {
  if (group_id < 0) return;
  auto it = group_id_to_view_id_.find(group_id);
  if (it == group_id_to_view_id_.end()) {
    std::set<int> view_set;
    view_set.insert(view_id);
    group_id_to_view_id_[group_id] = view_set;
  } else {
    group_id_to_view_id_[group_id].insert(view_id);
  }
}

void InspectorClientV8Impl::RemoveViewIdFromGroup(int group_id, int view_id) {
  auto it = group_id_to_view_id_.find(group_id);
  if (it == group_id_to_view_id_.end()) {
    return;
  }
  it->second.erase(view_id);
  if (it->second.empty()) {
    group_id_to_view_id_.erase(it);
  }
}

const std::set<int>& InspectorClientV8Impl::GetViewIdInGroup(int group_id) {
  auto it = group_id_to_view_id_.find(group_id);
  if (it != group_id_to_view_id_.end()) {
    return it->second;
  }
  return group_id_to_view_id_[kErrorGroupID];
}

int InspectorClientV8Impl::GetViewCountOfGroup(int group_id) {
  auto it = group_id_to_view_id_.find(group_id);
  if (it == group_id_to_view_id_.end()) {
    return 0;
  } else {
    return static_cast<int>(it->second.size());
  }
}

int InspectorClientV8Impl::GetViewIdOfDefaultGroupId(int group_id) {
  switch (group_id) {
    case kDefaultGroupID:
      return kDefaultViewID;
    case kDefaultWorkerGroupID:
      if (type_ != JsWorkerClient) return kErrorViewID;
      for (const auto& item : view_id_to_bundle_) {
        if (item.first > kErrorViewID) {
          return item.first;
        }
      }
    default:
      return kErrorViewID;
  }
}

void InspectorClientV8Impl::SetContextCreated(int group_id) {
  if (group_id < 0) return;
  group_context_created_.insert(group_id);
}

void InspectorClientV8Impl::RemoveContextCreated(int group_id) {
  if (group_id < 0) return;
  group_context_created_.erase(group_id);
}

bool InspectorClientV8Impl::GetContextCreated(int group_id) {
  if (group_id < 0) return false;
  auto it = group_context_created_.find(group_id);
  if (it != group_context_created_.end()) {
    return true;
  }
  return false;
}

std::vector<std::string> InspectorClientV8Impl::GetMessagePosterToChrome(
    const std::string& message, int view_id) {
  auto res = std::vector<std::string>();
  const std::unique_ptr<ScriptManager>& script_manager =
      GetScriptManagerByViewId(view_id);
  rapidjson::Document content;
  if (!ParseStrToJson(content, message)) {
    return res;
  }

  if (content.HasMember(kKeyId) && content[kKeyId].GetInt() == 0) {
    return res;
  } else if (content.HasMember(kKeyMethod) &&
             strcmp(content[kKeyMethod].GetString(),
                    kEventDebuggerScriptParsed) == 0 &&
             script_manager != nullptr) {
    int script_id = std::atoi(content[kKeyParams][kKeyScriptId].GetString());
    std::string script_url = content[kKeyParams][kKeyUrl].GetString();
    int script_view_id = GetScriptViewId(script_url);
    InsertScriptId(script_view_id, script_id);
    if (view_id < 0) {
      std::string id = content[kKeyParams][kKeyScriptId].GetString();
      script_manager->AddScriptId(id);
    }
    if (IsScriptViewDestroyed(script_url) || GetScriptIdInvalid(script_id) ||
        script_url.empty()) {
      return res;
    }
  } else if (content.HasMember(kKeyMethod) &&
             std::strcmp(content[kKeyMethod].GetString(),
                         kEventRuntimeConsoleAPICalled) == 0) {
    if (HandleMessageConsoleAPICalled(content)) {
      return res;
    }
  } else if (content.HasMember(kKeyId) && script_manager != nullptr) {
    script_manager->SetBreakpointId(content);
  }

  if (content.HasMember(kKeyResult) &&
      content[kKeyResult].HasMember(kKeyDebuggerId)) {
    content[kKeyResult].AddMember(
        rapidjson::Value(kKeyEngineType, content.GetAllocator()),
        rapidjson::Value(kKeyEngineV8, content.GetAllocator()),
        content.GetAllocator());
  }
  if (content.HasMember(kKeyParams)) {
    content[kKeyParams].AddMember(
        rapidjson::Value(kKeyViewId, content.GetAllocator()),
        rapidjson::Value(view_id), content.GetAllocator());
  }
  if (script_manager != nullptr && view_id < 0) {
    content = script_manager->MapScriptId(content, true, false);
  }

  AddWorkerSessionId(content);
  res.push_back(base::ToJson(content));
  return res;
}

std::vector<std::pair<int, std::string>>
InspectorClientV8Impl::GetMessagePostedToJSEngine(
    const rapidjson::Value& message, int view_id) {
  auto res = std::vector<std::pair<int, std::string>>();
  rapidjson::Document map_message;
  map_message.CopyFrom(message, map_message.GetAllocator());

  RemoveInvalidProperty(map_message);
  RemoveWorkerSessionId(map_message);
  const std::unique_ptr<ScriptManager>& script_manager =
      GetScriptManagerByViewId(view_id);
  if (script_manager != nullptr && view_id < 0) {
    map_message = script_manager->MapScriptId(map_message, false, true);
  }

  std::string method = map_message[kKeyMethod].GetString();
  if (method == kMethodDebuggerSetBreakpointsActive &&
      script_manager != nullptr) {
    bool new_active = map_message[kKeyParams][kKeyActive].GetBool();
    bool active = script_manager->GetBreakpointsActive();
    if (new_active == active) return res;
    script_manager->SetBreakpointsActive(new_active);
    for (const auto& view : view_id_to_bundle_) {
      res.emplace_back(view.first,
                       GetMessageSetBreakpointsActive(
                           new_active, map_message[kKeyId].GetInt()));
    }
    return res;
  } else if (method == kMethodDebuggerSetBreakpointByUrl &&
             script_manager != nullptr) {
    script_manager->SetBreakpointDetail(map_message);
  } else if (method == kMethodDebuggerRemoveBreakpoint &&
             script_manager != nullptr) {
    script_manager->RemoveBreakpoint(
        map_message[kKeyParams][kKeyBreakpointId].GetString());
  } else if (method == kMethodRuntimeEvaluate) {
    if (map_message[kKeyParams].HasMember(kKeyThrowOnSideEffect)) {
      map_message[kKeyParams].AddMember(
          rapidjson::Value(kKeyThrowOnSideEffect, map_message.GetAllocator()),
          rapidjson::Value(false), map_message.GetAllocator());
    }
    if (map_message.HasMember(kKeyParams)) {
      map_message[kKeyParams].AddMember(
          rapidjson::Value(kKeyDisableBreaks, map_message.GetAllocator()),
          rapidjson::Value(false), map_message.GetAllocator());
    }
  } else if (method == kMethodRuntimeEnable) {
    HandleMessageRuntimeEnableFromFrontend(view_id);
  } else if (method == kMethodDebuggerDisable) {
    bool result = HandleMessageDebuggerDisableFromFrontend(
        view_id, base::ToJson(map_message), res);
    if (result) return res;
  } else if (method == kMethodDebuggerEnable) {
    bool result = HandleMessageDebuggerEnableFromFrontend(
        view_id, base::ToJson(map_message), res);
    if (result) return res;
  } else if (method == kMethodDebuggerSetDebugActive) {
    HandleMessageDebuggerActive(view_id, map_message);
    return res;
  } else if (method == kMethodProfilerStart) {
    profile_start_ = true;
  } else if (method == kMethodProfilerStop) {
    profile_start_ = false;
  }
  res.emplace_back(view_id, base::ToJson(map_message));
  return res;
}

void InspectorClientV8Impl::SendMessageContextDestroyed(int view_id,
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
    destroyed_context_id_.push(context_id);
  }
}

void InspectorClientV8Impl::SendMessageRemoveScripts(int remove_view_id) {
  auto it = view_id_to_bundle_.find(remove_view_id);
  if (it != view_id_to_bundle_.end()) {
    int group_id = it->second.group_id_;
    auto view_set = GetViewIdInGroup(group_id);
    for (auto& view_id : view_set) {
      auto debugger = GetJSDebuggerByViewId(view_id).lock();
      if (!IsViewDestroyed(view_id) && debugger != nullptr) {
        rapidjson::Document document(rapidjson::kObjectType);
        document.AddMember(
            rapidjson::Value(kKeyMethod, document.GetAllocator()),
            rapidjson::Value(kEventDebuggerRemoveScriptsForLynxView,
                             document.GetAllocator()),
            document.GetAllocator());
        rapidjson::Document params(rapidjson::kObjectType);
        params.AddMember(rapidjson::Value(kKeyViewId, params.GetAllocator()),
                         rapidjson::Value(remove_view_id),
                         params.GetAllocator());
        document.AddMember(
            rapidjson::Value(kKeyParams, document.GetAllocator()), params,
            document.GetAllocator());
        debugger->ResponseFromJSEngine(base::ToJson(document));
      }
    }
  }
}

void InspectorClientV8Impl::CreateWorkerTarget(int view_id) {
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

void InspectorClientV8Impl::DestroyWorkerTarget(int view_id) {
  if (type_ == JsWorkerClient) {
    auto debugger = GetJSDebuggerByViewId(view_id).lock();
    if (debugger != nullptr) {
      debugger->ResponseFromJSEngine(
          GetMessageDetachFromTarget(worker_target_id_, worker_session_id_));
      debugger->ResponseFromJSEngine(
          GetMessageTargetDestroyed(worker_target_id_));
    }
    const std::unique_ptr<ScriptManager>& manager =
        GetScriptManagerByViewId(view_id);
    if (manager != nullptr) {
      manager->RemoveAllBreakpoints();
    }
  }
}

void InspectorClientV8Impl::AddWorkerSessionId(rapidjson::Document& message) {
  if (type_ == JsWorkerClient) {
    message.AddMember(
        rapidjson::Value(kKeySessionId, message.GetAllocator()),
        rapidjson::Value(worker_session_id_, message.GetAllocator()),
        message.GetAllocator());
  }
}

void InspectorClientV8Impl::RemoveWorkerSessionId(rapidjson::Value& message) {
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

void InspectorClientV8Impl::HandleMessageDebuggerActive(
    int view_id, const rapidjson::Value& message) {
  bool active = message[kKeyParams][kKeyActive].GetBool();
  std::shared_ptr<InspectorClientV8Impl> ref =
      std::static_pointer_cast<InspectorClientV8Impl>(shared_from_this());
  std::string runtime_mes =
      GetSimpleMessage(active ? kMethodRuntimeEnable : kMethodRuntimeDisable);
  std::string debugger_mes =
      GetSimpleMessage(active ? kMethodDebuggerEnable : kMethodDebuggerDisable);
  RunOnJSThread(view_id,
                [ref, runtime_mes = std::move(runtime_mes), view_id]() {
                  ref->DispatchMessageFromFrontendSync(runtime_mes, view_id);
                });
  RunOnJSThread(view_id,
                [ref, debugger_mes = std::move(debugger_mes), view_id]() {
                  ref->DispatchMessageFromFrontendSync(debugger_mes, view_id);
                });
}

bool InspectorClientV8Impl::HandleMessageDebuggerEnableFromFrontend(
    int view_id, const std::string& mes,
    std::vector<std::pair<int, std::string>>& mes_vec) {
  const std::unique_ptr<ScriptManager>& script_manager =
      GetScriptManagerByViewId(view_id);
  if (script_manager != nullptr && !script_manager->GetBreakpointsActive()) {
    script_manager->SetBreakpointsActive(true);
  }

  if (mes.find(kMethodDebuggerEnable) == std::string::npos ||
      disable_view_id_ == kErrorViewID || view_id == kDefaultViewID) {
    return false;
  }
  auto it = view_id_to_bundle_.find(view_id);
  if (it == view_id_to_bundle_.end() || it->second.single_group_) return false;
  auto disable_view_it = view_id_to_bundle_.find(disable_view_id_);
  if (disable_view_it == view_id_to_bundle_.end()) return false;
  int group_id = it->second.group_id_;
  int disable_group_id = disable_view_it->second.group_id_;
  if (disable_group_id != group_id) return false;
  if (disable_view_id_ != view_id) {
    mes_vec.emplace_back(view_id, mes);
    mes_vec.emplace_back(disable_view_id_,
                         GetSimpleMessage(kMethodDebuggerDisable));
    disable_view_id_ = kErrorViewID;
    return true;
  } else {
    auto view_set = GetViewIdInGroup(group_id);
    for (auto id : view_set) {
      if (id != view_id && !IsViewEnabled(id)) {
        mes_vec.emplace_back(id, GetSimpleMessage(kMethodDebuggerEnable));
        mes_vec.emplace_back(disable_view_id_,
                             GetSimpleMessage(kMethodDebuggerDisable));
        mes_vec.emplace_back(view_id, mes);
        mes_vec.emplace_back(id, GetSimpleMessage(kMethodDebuggerDisable));
        disable_view_id_ = kErrorViewID;
        return true;
      }
    }
  }
  return false;
}

bool InspectorClientV8Impl::HandleMessageDebuggerDisableFromFrontend(
    int view_id, const std::string& mes,
    std::vector<std::pair<int, std::string>>& mes_vec) {
  if (mes.find(kMethodDebuggerDisable) == std::string::npos) return false;
  mes_vec.emplace_back(view_id, GetSimpleMessage(kMethodRuntimeDisable));
  if (!running_nested_loop_ || view_id == kDefaultViewID || profile_start_) {
    return false;
  }
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end() && !it->second.single_group_) {
    auto group_id = it->second.group_id_;
    auto view_set = GetViewIdInGroup(group_id);
    for (const auto& id : view_set) {
      if (id != view_id && IsViewEnabled(id)) return false;
    }
    if (GetViewIdInGroup(group_id).size() > 1) {
      disable_view_id_ = view_id;
      return true;
    }
  }
  return false;
}

void InspectorClientV8Impl::HandleMessageRuntimeEnableFromFrontend(
    int view_id) {
  std::queue<int> que;
  {
    std::lock_guard<std::mutex> lock(destroyed_context_queue_mutex_);
    que.swap(destroyed_context_id_);
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

bool InspectorClientV8Impl::HandleMessageConsoleAPICalled(
    rapidjson::Document& message) {
  if (!message.HasMember(kKeyParams) ||
      !message[kKeyParams].HasMember(kKeyArgs)) {
    return false;
  }
  auto& args = message[kKeyParams][kKeyArgs];
  if (args.IsArray() && args.GetArray().Size() > 1 &&
      args[0].HasMember(kKeyType) &&
      strcmp(args[0][kKeyType].GetString(), kKeyStringType) == 0) {
    std::string value = args[0][kKeyValue].GetString();
    int runtime_id = kErrorViewID;
    std::string console_group_id = kErrorGroupStr;

    if (value.find(kKeyLepusRuntimeId) != std::string::npos) {
      runtime_id = std::stoi(value.substr(strlen(kKeyLepusRuntimeId) + 1));
      message[kKeyParams].AddMember(
          rapidjson::Value(kKeyConsoleTag, message.GetAllocator()),
          rapidjson::Value(kKeyEngineLepus, message.GetAllocator()),
          message.GetAllocator());
    } else if (value.find(kKeyRuntimeId) != std::string::npos) {
      runtime_id = std::stoi(value.substr(strlen(kKeyRuntimeId) + 1));
    } else if (value.find(kKeyGroupId) != std::string::npos) {
      console_group_id = value.substr(strlen(kKeyGroupId) + 1);
    } else {
      return false;
    }
    message[kKeyParams][kKeyArgs].Erase(message[kKeyParams][kKeyArgs].Begin());

    if (runtime_id != kErrorViewID) {
      int console_id = GetViewIdByRuntimeId(runtime_id);
      if (console_id == kErrorViewID) {
        return true;
      }
      message[kKeyParams].AddMember(
          rapidjson::Value(kKeyConsoleId, message.GetAllocator()),
          rapidjson::Value(console_id), message.GetAllocator());
    } else if (console_group_id != kErrorGroupStr) {
      message[kKeyParams].AddMember(
          rapidjson::Value(kKeyGroupId, message.GetAllocator()),
          rapidjson::Value(console_group_id, message.GetAllocator()),
          message.GetAllocator());
    }
  }
  return false;
}

void InspectorClientV8Impl::RemoveInvalidProperty(rapidjson::Value& message) {
  for (auto it = message.MemberBegin(); it != message.MemberEnd();) {
    auto key = it->name.GetString();
    if (strcmp(key, kKeyId) && strcmp(key, kKeyMethod) &&
        strcmp(key, kKeyParams) && strcmp(key, kKeySessionId)) {
      it = message.EraseMember(it);
    } else {
      it++;
    }
  }
}

void InspectorClientV8Impl::SetViewEnabled(const std::string& mes,
                                           int view_id) {
  auto enable_pos = mes.find(kMethodDebuggerEnable);
  auto disable_pos = mes.find(kMethodDebuggerDisable);
  if (enable_pos == std::string::npos && disable_pos == std::string::npos)
    return;
  bool enabled = enable_pos != std::string::npos;
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.enabled_ = enabled;
  }
}

bool InspectorClientV8Impl::IsViewEnabled(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    return it->second.enabled_;
  }
  return false;
}

void InspectorClientV8Impl::InsertRuntimeId(int runtime_id, int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    it->second.runtime_id_ = runtime_id;
  }
  runtime_id_to_view_id_[runtime_id] = view_id;
}

void InspectorClientV8Impl::RemoveRuntimeId(int view_id) {
  auto it = view_id_to_bundle_.find(view_id);
  if (it != view_id_to_bundle_.end()) {
    runtime_id_to_view_id_.erase(it->second.runtime_id_);
    it->second.runtime_id_ = kDefaultViewID;
  }
}

int InspectorClientV8Impl::GetViewIdByRuntimeId(int runtime_id) {
  auto it = runtime_id_to_view_id_.find(runtime_id);
  if (it != runtime_id_to_view_id_.end()) {
    return it->second;
  }
  return kErrorViewID;
}

void InspectorClientV8Impl::Pause() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    running_nested_loop_ = true;
    waiting_for_message_ = true;
  }

  while (waiting_for_message_) {
    FlushMessageQueue();
    if (waiting_for_message_) {
      std::unique_lock<std::mutex> lock(mutex_);
      cv_.wait(lock);
    }
  }
}

void InspectorClientV8Impl::QuitPause() {
  std::lock_guard<std::mutex> lock(mutex_);
  running_nested_loop_ = false;
  waiting_for_message_ = false;
}

void InspectorClientV8Impl::FlushMessageQueue() {
  while (!message_queue_.empty()) {
    std::string mes;
    int view_id;
    {
      std::lock_guard<std::mutex> lock(message_queue_mutex_);
      const auto& pair = message_queue_.front();
      mes = pair.second;
      view_id = pair.first;
      message_queue_.pop();
    }
    DispatchMessageFromFrontendSync(mes, view_id);
  }
}

void InspectorClientV8Impl::RunOnJSThread(int view_id, base::closure closure) {
  auto debugger = GetJSDebuggerByViewId(view_id).lock();
  if (debugger) {
    debugger->RunOnJSThread(std::move(closure), type_ == JsWorkerClient);
  }
}

void InspectorClientV8Impl::SetStopAtEntry(bool stop_at_entry, int view_id) {
  const std::shared_ptr<ChannelImpl>& channel = GetChannelByViewId(view_id);
  if (channel != nullptr) {
    if (stop_at_entry) {
      channel->SchedulePauseOnNextStatement(kStopAtEntryReason);
    } else {
      channel->CancelPauseOnNextStatement();
    }
  }
}

}  // namespace devtool
}  // namespace lynx

#endif
