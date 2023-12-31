// Copyright 2019 The Lynx Authors. All rights reserved.
#include "lepus_inspector_session_impl.h"

#include "lepus/context.h"

namespace lynx {
namespace lepus {
class Context;
}
}  // namespace lynx

namespace lepus_inspector {
class LepusInspectorImpl;
LepusInspectorImpl::LepusInspectorImpl(lynx::lepus::Context* ctx) : ctx_(ctx) {
  ctx_->SetInspector(this);
}

LepusInspectorImpl::~LepusInspectorImpl() { ctx_->SetInspector(nullptr); }

std::unique_ptr<LepusInspector> LepusInspector::create(
    lynx::lepus::Context* ctx, LepusInspectorClient* inspector_client) {
  std::unique_ptr<LepusInspector> client =
      std::unique_ptr<LepusInspector>(new LepusInspectorImpl(ctx));
  // second param group id is only needed when debug in js thread, default
  // value: empty string
  client->SetInspectorClient(inspector_client, "");
  return client;
}

std::unique_ptr<LepusInspectorSession> LepusInspectorImpl::connect(
    int contextGroupId, LepusInspector::LepusChannel* channel,
    const std::string& state) {
  int sessionId = ++lastSessionId_;
  std::unique_ptr<LepusInspectorSessionImpl> session =
      LepusInspectorSessionImpl::create(this, contextGroupId, sessionId,
                                        channel, state);
  sessions_[contextGroupId][sessionId] = session.get();
  return std::move(session);
}

void LepusInspectorImpl::SetInspectorClient(LepusInspectorClient* client,
                                            const std::string& group_id) {
  client_ = client;
  LOGI("lepus debug: " << client_ << " LepusInspectorImpl::SetInspectorClient");
}

LepusInspectorSessionImpl::LepusInspectorSessionImpl(
    LepusInspectorImpl* inspector, int contextGroupId, int sessionId,
    LepusInspector::LepusChannel* channel, const std::string& savedState)
    : channel_(channel), inspector_(inspector) {
  lynx::lepus::Context* ctx = inspector_->LepusContext();
  ctx->SetSession(this);
}

void LepusInspectorSessionImpl::dispatchProtocolMessage(
    const std::string& message) {
  LOGI("lepus debug: LepusInspectorSessionImpl::dispatchProtocolMessage "
       << message);
  lynx::lepus::Context* ctx = inspector_->LepusContext();
  ctx->ProcessPausedMessages(ctx, message);
}

void LepusInspectorSessionImpl::sendProtocolResponse(
    int callId, const std::string& message) {
  LOGI("lepus debug: LepusInspectorSessionImpl::sendProtocolResponse "
       << callId << " " << message);
  channel_->sendResponse(callId, message);
}

void LepusInspectorSessionImpl::sendProtocolNotification(
    const std::string& message) {
  channel_->sendNotification(message);
}

void LepusInspectorSessionImpl::flushProtocolNotifications() {
  channel_->flushProtocolNotifications();
}

std::unique_ptr<LepusInspectorSessionImpl> LepusInspectorSessionImpl::create(
    LepusInspectorImpl* inspector, int contextGroupId, int sessionId,
    LepusInspector::LepusChannel* channel, const std::string& state) {
  return std::unique_ptr<LepusInspectorSessionImpl>(
      new LepusInspectorSessionImpl(inspector, contextGroupId, sessionId,
                                    channel, state));
}

void LepusInspectorSessionImpl::schedulePauseOnNextStatement(
    const std::string& breakReason, const std::string& message) {
  // Debugger.stopAtEntry
  std::string stopAtEntry_message =
      "{\"id\": 0, \"method\": \"Debugger.stopAtEntry\"}";
  lynx::lepus::Context* ctx = inspector_->LepusContext();
  ctx->ProcessPausedMessages(ctx, stopAtEntry_message);
}

void LepusInspectorSessionImpl::cancelPauseOnNextStatement() {}

LepusInspectorSessionImpl::~LepusInspectorSessionImpl() = default;
}  // namespace lepus_inspector
