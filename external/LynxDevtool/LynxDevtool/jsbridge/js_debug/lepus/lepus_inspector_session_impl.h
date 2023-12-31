// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LEPUS_LEPUS_INSPECTOR_SESSION_IMPL_H
#define LEPUS_LEPUS_INSPECTOR_SESSION_IMPL_H

#include <map>
#include <unordered_map>
#include <vector>

#include "lepus/lepus_inspector.h"

namespace lynx {
namespace lepus {
class Context;
}
}  // namespace lynx

namespace lepus_inspector {
class LepusInspectorImpl;
class LepusInspectorSessionImpl;
class LepusInspectorSessionImpl : public LepusInspectorSession {
 public:
  static std::unique_ptr<LepusInspectorSessionImpl> create(
      LepusInspectorImpl*, int contextGroupId, int sessionId,
      LepusInspector::LepusChannel*, const std::string& state);
  ~LepusInspectorSessionImpl() override;

  void dispatchProtocolMessage(const std::string& message) override;
  void schedulePauseOnNextStatement(const std::string& breakReason,
                                    const std::string& breakDetails) override;
  void cancelPauseOnNextStatement() override;
  void sendProtocolResponse(int callId, const std::string& message);
  void sendProtocolNotification(const std::string& message);
  void flushProtocolNotifications();

 private:
  LepusInspectorSessionImpl(LepusInspectorImpl*, int contextGroupId,
                            int sessionId, LepusInspector::LepusChannel*,
                            const std::string& state);

  LepusInspectorImpl* Inspector() const { return inspector_; }
  LepusInspector::LepusChannel* channel_;
  LepusInspectorImpl* inspector_;
};

class LepusInspectorImpl : public LepusInspector {
 public:
  LepusInspectorImpl(lynx::lepus::Context*);
  lynx::lepus::Context* LepusContext() { return ctx_; };
  ~LepusInspectorImpl() override;

  LepusInspectorClient* Client() { return client_; }
  std::unique_ptr<LepusInspectorSession> connect(
      int contextGroupId, LepusInspector::LepusChannel*,
      const std::string& state) override;
  void SetInspectorClient(LepusInspectorClient*, const std::string&) override;

 private:
  LepusInspectorClient* client_;

  lynx::lepus::Context* ctx_;
  int lastSessionId_ = 0;
  std::unordered_map<int, std::map<int, LepusInspectorSessionImpl*>> sessions_;
};
}  // namespace lepus_inspector

#endif  // LEPUS_LEPUS_INSPECTOR_SESSION_IMPL_H
