// Copyright 2019 The Lynx Authors. All rights reserved.
#include "quickjs_inspector_session_impl.h"

namespace lynx {
namespace piper {
class QuickjsContextWrapper;
}
}  // namespace lynx

namespace lepus_inspector {

class QJSInspectorImpl;
QJSInspectorImpl::QJSInspectorImpl(lynx::piper::QuickjsContextWrapper* ctx)
    : ctx_(ctx) {
  ctx_->SetInspector(this);
}

QJSInspectorImpl::~QJSInspectorImpl() {
  ctx_->SetInspector(nullptr);
  ctx_->ClearSessions();
}

std::unique_ptr<QJSInspector> QJSInspector::create(
    lynx::piper::QuickjsContextWrapper* ctx,
    LepusInspectorClient* inspector_client, const std::string& group_id) {
  std::unique_ptr<QJSInspector> client =
      std::unique_ptr<QJSInspector>(new QJSInspectorImpl(ctx));
  client->SetInspectorClient(inspector_client, group_id);
  return client;
}

std::unique_ptr<LepusInspectorSession> QJSInspectorImpl::connect(
    const std::string& group_id, QJSInspector::QJSChannel* channel,
    const std::string& state, int32_t view_id) {
  std::unique_ptr<QJSInspectorSessionImpl> session =
      QJSInspectorSessionImpl::create(this, group_id, view_id, channel, state);
  sessions_[group_id][view_id] = session.get();
  return std::move(session);
}

void QJSInspectorImpl::SetInspectorClient(LepusInspectorClient* client,
                                          const std::string& group_id) {
  client_ = client;
  group_id_ = group_id;
  LOGI("qjs debug: client: " << client_ << ", group_id: " << group_id_
                             << " LepusInspectorImpl::SetInspectorClient");
}

QJSInspectorSessionImpl::QJSInspectorSessionImpl(
    QJSInspectorImpl* inspector, const std::string& group_id, int32_t view_id,
    QJSInspector::QJSChannel* channel, const std::string& savedState)
    : channel_(channel), inspector_(inspector), view_id_(view_id) {
  lynx::piper::QuickjsContextWrapper* ctx = inspector_->QJSContext();
  LOGI("qjs debug: create QJSInspectorSessionImpl, this: "
       << this << ", inspector: " << inspector << ", context: " << ctx);
  ctx->SetSession(view_id, this);
}

void QJSInspectorSessionImpl::dispatchProtocolMessage(
    const std::string& message) {
  LOGI("qjs debug: LepusInspectorSessionImpl::dispatchProtocolMessage "
       << message);
  lynx::piper::QuickjsContextWrapper* ctx = inspector_->QJSContext();
  ctx->ProcessPausedMessages(ctx->getContext(), message, view_id_);
}

void QJSInspectorSessionImpl::sendProtocolResponse(int callId,
                                                   const std::string& message) {
  LOGI("qjs debug: LepusInspectorSessionImpl::sendProtocolResponse "
       << callId << " " << message);
  channel_->sendResponse(callId, message);
}

void QJSInspectorSessionImpl::sendProtocolNotification(
    const std::string& message) {
  channel_->sendNotification(message);
}

void QJSInspectorSessionImpl::flushProtocolNotifications() {
  channel_->flushProtocolNotifications();
}

std::unique_ptr<QJSInspectorSessionImpl> QJSInspectorSessionImpl::create(
    QJSInspectorImpl* inspector, const std::string& group_id, int32_t view_id,
    QJSInspector::QJSChannel* channel, const std::string& state) {
  return std::unique_ptr<QJSInspectorSessionImpl>(new QJSInspectorSessionImpl(
      inspector, group_id, view_id, channel, state));
}

void QJSInspectorSessionImpl::schedulePauseOnNextStatement(
    const std::string& breakReason, const std::string& message) {
  // Debugger.stopAtEntry
  std::string stopAtEntry_message =
      "{\"id\": 0, \"method\": \"Debugger.stopAtEntry\"}";
  lynx::piper::QuickjsContextWrapper* ctx = inspector_->QJSContext();
  ctx->ProcessPausedMessages(ctx->getContext(), stopAtEntry_message, view_id_);
}

void QJSInspectorSessionImpl::cancelPauseOnNextStatement() {}
QJSInspectorSessionImpl::~QJSInspectorSessionImpl() {
  lynx::piper::QuickjsContextWrapper* ctx = inspector_->QJSContext();
  ctx->RemoveSession(view_id_);
}

// get group id
const std::string& QJSInspectorImpl::GetGroupID() { return group_id_; }
}  // namespace lepus_inspector
