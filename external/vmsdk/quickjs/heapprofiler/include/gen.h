#ifndef QUICKJS_HEAP_SNAPSHOT_GEN_H_
#define QUICKJS_HEAP_SNAPSHOT_GEN_H_

#include "quickjs/heapprofiler/include/edge.h"
#include "quickjs/heapprofiler/include/entry.h"
#include "quickjs/heapprofiler/include/heapexplorer.h"

namespace quickjs {
namespace heapprofiler {

class HeapObjectIdMaps {
 public:
  // these entry's type is kSynthetic
  HeapObjectIdMaps() { next_id_ = kFirstAvailiableObjectId; }
  static constexpr SnapshotObjectId kRootEntryId = 1;
  static constexpr SnapshotObjectId SyntheicEntryId[static_cast<uint32_t>(
      Root::kNumberOfRoots)] = {3, 5, 7, 9};

  static constexpr uint64_t kObjectIdStep = 2;

  static constexpr SnapshotObjectId kFirstAvailiableObjectId =
      SyntheicEntryId[static_cast<int32_t>(Root::kNumberOfRoots) - 1] + 2;

  SnapshotObjectId GetEntryObjectId(const LEPUSValue& value);

  std::ostream& DumpObjectIdMaps(std::ostream& output);

  SnapshotObjectId LastAssignedId() { return next_id_; }

 private:
  SnapshotObjectId GetHeapObjId(HeapPtr ptr);
  SnapshotObjectId next_id_;
  std::unordered_map<HeapPtr, SnapshotObjectId> objectid_maps_;
};

class ProgressReportInterface {
 public:
  virtual ~ProgressReportInterface() = default;

  virtual void ProgressResult(uint32_t done, uint32_t total, bool finished) = 0;
};

class HeapSnapshotGenerator {
 public:
  using HeapThing = void*;
  using HeapEntriesMap = std::unordered_map<HeapThing, HeapEntry*>;

  HeapSnapshotGenerator(HeapSnapshot* snapshot, LEPUSContext*,
                        ProgressReportInterface* report);

  HeapSnapshotGenerator(const HeapSnapshotGenerator&) = delete;
  HeapSnapshotGenerator& operator=(const HeapSnapshotGenerator&) = delete;

  void GenerateSnapshot();

  HeapEntry* FindEntry(const LEPUSValue& value) {
    if (LEPUS_VALUE_HAS_REF_COUNT(value)) {
      auto it = entries_map_.find(LEPUS_VALUE_GET_PTR(value));
      return it != entries_map_.end() ? it->second : nullptr;
    }
    return nullptr;
  }

  HeapEntry* AddEntry(const LEPUSValue& value, HeapEntriesAllocator* alloctor) {
    if (LEPUS_VALUE_HAS_REF_COUNT(value)) {
      return entries_map_
          .emplace(LEPUS_VALUE_GET_PTR(value), alloctor->AllocateEntry(value))
          .first->second;
    }
    return alloctor->AllocateEntry(value);
  }

  HeapEntry* FindOrAddEntry(const LEPUSValue& value,
                            HeapEntriesAllocator* allocator) {
    HeapEntry* entry = FindEntry(value);
    return entry != nullptr ? entry : AddEntry(value, allocator);
  }

  LEPUSContext* context() const { return context_; }

 private:
  // main function for build object graph

  void ProgressGenResult();
  void FillReferences();
  HeapSnapshot* snapshot_;
  LEPUSContext* context_;
  QjsHeapExplorer quickjs_heap_explorer_;
  HeapEntriesMap entries_map_;  // ptr/id -> HeapEntry*
  ProgressReportInterface* reporter_;

  // TODO: add progress report to devtool
};

}  // namespace heapprofiler
}  // namespace quickjs

#endif