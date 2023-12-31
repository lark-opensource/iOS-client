// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef QUICKJS_INSPECTOR_SESSION_IMPL_H
#define QUICKJS_INSPECTOR_SESSION_IMPL_H

#include <map>
#include <unordered_map>
#include <vector>

#include "Lynx/lepus/lepus_inspector.h"
#include "jsbridge/quickjs/quickjs_context_wrapper.h"

namespace lepus_inspector {

class QJSInspectorImpl;
class LepusInspectorSession;

class QJSInspectorSessionImpl : public LepusInspectorSession {
 public:
  static std::unique_ptr<QJSInspectorSessionImpl> create(
      QJSInspectorImpl*, const std::string& contextGroupId, int sessionId,
      QJSInspector::QJSChannel*, const std::string& state);
  ~QJSInspectorSessionImpl() override;

  void dispatchProtocolMessage(const std::string& message) override;
  void schedulePauseOnNextStatement(const std::string& breakReason,
                                    const std::string& breakDetails) override;
  void cancelPauseOnNextStatement() override;
  void sendProtocolResponse(int callId, const std::string& message);
  void sendProtocolNotification(const std::string& message);
  void flushProtocolNotifications();

 private:
  QJSInspectorSessionImpl(QJSInspectorImpl*, const std::string&, int32_t,
                          QJSInspector::QJSChannel*, const std::string& state);

  QJSInspectorImpl* Inspector() const { return inspector_; }
  QJSInspector::QJSChannel* channel_;
  QJSInspectorImpl* inspector_;
  int32_t view_id_;
};

using InspectorSessionMap =
    std::unordered_map<std::string, std::map<int, QJSInspectorSessionImpl*>>;

class QJSInspectorImpl : public QJSInspector {
 public:
  QJSInspectorImpl(lynx::piper::QuickjsContextWrapper*);
  lynx::piper::QuickjsContextWrapper* QJSContext() { return ctx_; };
  ~QJSInspectorImpl() override;

  LepusInspectorClient* Client() { return client_; }
  std::unique_ptr<LepusInspectorSession> connect(
      const std::string& contextGroupId, QJSInspector::QJSChannel*,
      const std::string& state, int32_t view_id) override;
  void SetInspectorClient(LepusInspectorClient*, const std::string&) override;

  const std::string& GetGroupID();

 private:
  LepusInspectorClient* client_;
  lynx::piper::QuickjsContextWrapper* ctx_;
  InspectorSessionMap sessions_;
  std::string group_id_;
};
}  // namespace lepus_inspector

#endif  // QUICKJS_INSPECTOR_SESSION_IMPL_H
