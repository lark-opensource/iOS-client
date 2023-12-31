// Copyright 2022 The VmSdk Authors. All rights reserved.

#include "devtool/quickjs/heapprofiler/heapprofiler.h"

#include "devtool/quickjs/debugger/debugger.h"
#include "devtool/quickjs/debugger_inner.h"

#ifdef ENABLE_HEAPPROFILER
#include "quickjs/heapprofiler/include/heapprofiler.h"
namespace qjs_insepctor {
namespace protocol {
namespace heapprofiler {

// Fronted interface
class DevtoolFronted : public quickjs::heapprofiler::Fronted {
 public:
  explicit DevtoolFronted(LEPUSContext* ctx) : context_(ctx){};
  virtual ~DevtoolFronted() = default;

  // send notification
  virtual void AddHeapSnapshotChunk(const std::string& chunk) override;
  virtual void ReportHeapSnapshotProgress(uint32_t done, uint32_t total,
                                          bool finished) override;

  // send reponse

  virtual void SendReponse(LEPUSValue message) override;

  // TODO: other events
 private:
  LEPUSContext* context_;
};

void DevtoolFronted::AddHeapSnapshotChunk(const std::string& chunk) {
  if (context_ == nullptr) return;

  LEPUSValue chunkvalue = LEPUS_NewString(context_, chunk.c_str());
  LEPUSValue params = LEPUS_NewObject(context_);
  LEPUS_SetPropertyStr(context_, params, "chunk", chunkvalue);
  SendNotification(context_, "HeapProfiler.addHeapSnapshotChunk", params);
}

void DevtoolFronted::ReportHeapSnapshotProgress(uint32_t done, uint32_t total,
                                                bool finished) {
  if (context_ == nullptr) return;

  LEPUSValue param = LEPUS_NewObject(context_);

  LEPUS_SetPropertyStr(context_, param, "done", LEPUS_NewInt64(context_, done));
  LEPUS_SetPropertyStr(context_, param, "total",
                       LEPUS_NewInt64(context_, total));
  LEPUS_SetPropertyStr(context_, param, "finished",
                       LEPUS_NewBool(context_, finished));
  SendNotification(context_, "HeapProfiler.reportHeapSnapshotProgress", param);
}

void DevtoolFronted::SendReponse(LEPUSValue message) {
  LEPUSValue nullobj = LEPUS_NewObject(context_);
  SendResponse(context_, message, nullobj);
}

}  // namespace heapprofiler
}  // namespace protocol
}  // namespace qjs_insepctor

using namespace quickjs::heapprofiler;
void HandleHeapProfilerProtocols(DebuggerParams* param) {
  GetQjsHeapProfilerImplInstance().TakeHeapSnapshot(
      param->ctx, param->message,
      std::make_shared<qjs_insepctor::protocol::heapprofiler::DevtoolFronted>(
          param->ctx));
}

#else

void HandleHeapProfilerProtocols(DebuggerParams* param) { return; }
#endif
