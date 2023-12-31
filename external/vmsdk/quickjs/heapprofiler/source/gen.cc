#include "quickjs/heapprofiler/include/gen.h"

#include <ostream>
#ifdef __cplusplus
extern "C" {
#endif

#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

namespace quickjs {
namespace heapprofiler {

SnapshotObjectId HeapObjectIdMaps::GetHeapObjId(HeapPtr ptr) {
  auto itr = objectid_maps_.find(ptr);

  if (itr != objectid_maps_.end()) {
    return itr->second;
  }
  objectid_maps_.emplace(ptr, (next_id_ += kObjectIdStep));
  return next_id_;
}

std::ostream& HeapObjectIdMaps::DumpObjectIdMaps(std::ostream& output) {
  std::string header = "Object Id Maps: \nObjAddress  : ObjectId\n";
  output << header.c_str();
  for (auto& itr : objectid_maps_) {
    output << (itr.first) << " : " << itr.second << "\n";
  }
  return output;
}

SnapshotObjectId HeapObjectIdMaps::GetEntryObjectId(const LEPUSValue& value) {
  // only allocate entry if value's tag < 0 or value is number
  if (LEPUS_VALUE_HAS_REF_COUNT(value)) {
    // means value is an object, using it's address represent ID
    return GetHeapObjId(LEPUS_VALUE_GET_PTR(value));
  }
  return (next_id_ += kObjectIdStep);
}

HeapSnapshotGenerator::HeapSnapshotGenerator(HeapSnapshot* snapshot,
                                             LEPUSContext* ctx,
                                             ProgressReportInterface* report)
    : snapshot_(snapshot),
      context_(ctx),
      quickjs_heap_explorer_(snapshot, ctx),
      reporter_(report) {}

void HeapSnapshotGenerator::GenerateSnapshot() {
  // TODO: 实现
  // 1. GC
  // 2. count total obj
  // 3. Traverse the obj list and alloc entry for obj
  // 4. Iterate and extract every obj
  LEPUS_RunGC(LEPUS_GetRuntime(context_));

  snapshot_->AddSyntheticRootEntries();
  FillReferences();
  snapshot_->FillChildren();
  ProgressGenResult();

  snapshot_->RememberLastJsObjectId();
  return;
}

void HeapSnapshotGenerator::FillReferences() {
  quickjs_heap_explorer_.IterateAndExtractReference(this);
}

void HeapSnapshotGenerator::ProgressGenResult() {
  if (!reporter_) return;
  reporter_->ProgressResult(snapshot_->entries().size(),
                            snapshot_->entries().size(), true);
}
}  // namespace heapprofiler
}  // namespace quickjs