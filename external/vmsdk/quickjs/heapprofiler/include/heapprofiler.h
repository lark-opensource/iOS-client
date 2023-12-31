#ifndef QUICKJS_HEAP_PROFILE_H_
#define QUICKJS_HEAP_PROFILE_H_

#include <memory>
#include <vector>

#include "quickjs/heapprofiler/include/gen.h"
#include "quickjs/heapprofiler/include/serialize.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

namespace quickjs {
namespace heapprofiler {

class HeapSnapshot;
class HeapObjectIdMaps;

class HeapProfiler {
 public:
  explicit HeapProfiler();
  ~HeapProfiler() = default;
  HeapProfiler(const HeapProfiler&) = delete;
  HeapProfiler& operator=(const HeapProfiler&) = delete;

  HeapSnapshot* TakeSnapshot(LEPUSContext* ctx,
                             ProgressReportInterface* reporter);

  std::size_t GetSnapshotCount() const { return snapshots_.size(); }
  HeapSnapshot* GetSnapshot(uint32_t idx) const {
    return snapshots_[idx].get();
  }

  void DeleteAllSnapShots();
  void RemoveSnapshot(HeapSnapshot*);

  bool IsTakingSnapshot() const { return is_takingsnapshot; }
  LEPUSContext* context() const { return context_; }
  HeapObjectIdMaps* object_id_maps() const { return objectids_.get(); }

  std::ostream& DumpObjectIdMaps(std::ostream& output);

 private:
  LEPUSContext* context_ = nullptr;
  std::vector<std::unique_ptr<HeapSnapshot>> snapshots_;
  std::unique_ptr<HeapObjectIdMaps> objectids_;
  bool is_takingsnapshot = false;
};

class Fronted {
 public:
  virtual void AddHeapSnapshotChunk(const std::string& chunk) = 0;
  virtual void ReportHeapSnapshotProgress(uint32_t done, uint32_t total,
                                          bool finished) = 0;

  // send reponse
  virtual void SendReponse(LEPUSValue message) = 0;
};

class HeapSnapshotOutputStream : public quickjs::heapprofiler::OutputStream {
 public:
  explicit HeapSnapshotOutputStream(const std::shared_ptr<Fronted>& fronted)
      : mfronted_(fronted) {}

  virtual uint32_t GetChunkSize() override {
    return 10240;  // 10K
  }

  virtual void WriteChunk(const std::string& output) override {
    mfronted_->AddHeapSnapshotChunk(output);
  }

 private:
  std::shared_ptr<Fronted> mfronted_;
};

class HeapSnapshotGeneratorProgressReport
    : public quickjs::heapprofiler::ProgressReportInterface {
 public:
  HeapSnapshotGeneratorProgressReport(const std::shared_ptr<Fronted>& front)
      : mfronted_(front) {}
  virtual void ProgressResult(uint32_t done, uint32_t total, bool finished) {
    mfronted_->ReportHeapSnapshotProgress(done, total, finished);
  }

 private:
  std::shared_ptr<Fronted> mfronted_;
};

class QjsHeapProfilerImpl {
 public:
  QjsHeapProfilerImpl() = default;
  QjsHeapProfilerImpl(const QjsHeapProfilerImpl&) = delete;
  QjsHeapProfilerImpl& operator=(const QjsHeapProfilerImpl&) = delete;

  void TakeHeapSnapshot(LEPUSContext* ctx, LEPUSValue message,
                        const std::shared_ptr<Fronted>& fronted);
  // for android
  void TakeHeapSnapshot(LEPUSContext* ctx,
                        const std::shared_ptr<Fronted>& fronted);

  HeapSnapshot* TakeHeapSnapshot(LEPUSContext*);

 private:
  auto* FindOrNewHeapProfiler(LEPUSContext* ctx);
  std::unordered_map<LEPUSRuntime*, std::unique_ptr<HeapProfiler>> profilers_;
};
// qjs heapprofiler instance
QjsHeapProfilerImpl& GetQjsHeapProfilerImplInstance();

}  // namespace heapprofiler
}  // namespace quickjs

#endif