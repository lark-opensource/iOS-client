#include "quickjs/heapprofiler/include/heapprofiler.h"

#include <ostream>

#include "quickjs/heapprofiler/include/gen.h"
#include "quickjs/heapprofiler/include/serialize.h"

namespace quickjs {
namespace heapprofiler {

// online close
#define DUMP_OBJINFO 0

HeapProfiler::HeapProfiler() : objectids_(new HeapObjectIdMaps()) {}

void HeapProfiler::DeleteAllSnapShots() { snapshots_.clear(); }

void HeapProfiler::RemoveSnapshot(HeapSnapshot* snapshot) {
  snapshots_.erase(
      std::find_if(snapshots_.begin(), snapshots_.end(),
                   [&snapshot](const std::unique_ptr<HeapSnapshot>& entry) {
                     return entry.get() == snapshot;
                   }));
}

HeapSnapshot* HeapProfiler::TakeSnapshot(LEPUSContext* ctx,
                                         ProgressReportInterface* reporter) {
  context_ = ctx;
  is_takingsnapshot = true;
  HeapSnapshot* result = new HeapSnapshot(this);
  {
    HeapSnapshotGenerator generator(result, context_, reporter);
    generator.GenerateSnapshot();
    snapshots_.emplace_back(result);
  }
  is_takingsnapshot = false;
  context_ = nullptr;
  return result;
}

std::ostream& HeapProfiler::DumpObjectIdMaps(std::ostream& output) {
  return objectids_->DumpObjectIdMaps(output);
}

QjsHeapProfilerImpl& GetQjsHeapProfilerImplInstance() {
  thread_local static QjsHeapProfilerImpl instance;
  return instance;
}

auto* QjsHeapProfilerImpl::FindOrNewHeapProfiler(LEPUSContext* ctx) {
  LEPUSRuntime* rt = LEPUS_GetRuntime(ctx);
  auto itr = profilers_.find(rt);
  if (itr != profilers_.end()) {
    return itr->second.get();
  } else {
    auto qjs_heapprofiler = new HeapProfiler();
    profilers_.emplace(rt, qjs_heapprofiler);
    return qjs_heapprofiler;
  }
}

void QjsHeapProfilerImpl::TakeHeapSnapshot(
    LEPUSContext* ctx, const std::shared_ptr<Fronted>& fronted) {
  auto* profiler = FindOrNewHeapProfiler(ctx);

  auto progress_report =
      std::make_unique<HeapSnapshotGeneratorProgressReport>(fronted);

  // snapshot result
  auto* snapshot = profiler->TakeSnapshot(ctx, progress_report.get());

  // serializer tool
  HeapSnapshotJSONSerializer serializer(snapshot);

  // output tool, serializer snapshot to string to fronted
  HeapSnapshotOutputStream stream(fronted);

  serializer.Serialize(&stream);

  profiler->RemoveSnapshot(snapshot);

// if need, dump object -> id map
#if DUMP_OBJINFO
  std::ostringstream id_infos;
  profiler->DumpObjectIdMaps(id_infos);
  lepus_heap_dump_file(id_infos.str(), "ids");
#endif
}

void QjsHeapProfilerImpl::TakeHeapSnapshot(
    LEPUSContext* ctx, LEPUSValue message,
    const std::shared_ptr<Fronted>& fronted) {
  TakeHeapSnapshot(ctx, fronted);
  fronted->SendReponse(message);
}

HeapSnapshot* QjsHeapProfilerImpl::TakeHeapSnapshot(LEPUSContext* ctx) {
  auto* profiler = FindOrNewHeapProfiler(ctx);

  return profiler->TakeSnapshot(ctx, nullptr);
}
}  // namespace heapprofiler
}  // namespace quickjs