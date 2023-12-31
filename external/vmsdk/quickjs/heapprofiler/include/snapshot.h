#ifndef HEAP_SNAPSHOT_H_
#define HEAP_SNAPSHOT_H_

#include <queue>
#include <unordered_map>

#include "quickjs/heapprofiler/include/entry.h"

namespace quickjs {
namespace heapprofiler {
class HeapProfiler;

class HeapSnapshot {
 public:
  HeapSnapshot(HeapProfiler* profiler) : profiler_(profiler) {
    memset(subroot_entries_, 0, sizeof(subroot_entries_));
  }
  HeapSnapshot(const HeapSnapshot&) = delete;
  HeapSnapshot& operator=(const HeapSnapshot&) = delete;
  void Delete();

  HeapProfiler* profiler() const { return profiler_; }
  std::deque<HeapEntry>& entries() { return entries_; }
  const std::deque<HeapEntry>& entries() const { return entries_; }
  std::deque<HeapGraphEdge>& edges() { return edges_; }
  const std::deque<HeapGraphEdge>& edges() const { return edges_; }
  std::vector<HeapGraphEdge*>& childrens() { return children_; }

  bool is_complete() const { return !children_.empty(); }

  HeapEntry* AddEntry(HeapEntry::Type type, const char* name,
                      SnapshotObjectId id, size_t size);

  HeapEntry* AddEntry(HeapEntry::Type, const std::string& name,
                      SnapshotObjectId id, size_t size);

  void FillChildren();
  void AddSyntheticRootEntries();
  HeapEntry* GetEntryById(SnapshotObjectId id);

  HeapEntry* root() const { return root_entry_; }
  HeapEntry* subroot(Root root) {
    return subroot_entries_[static_cast<uint32_t>(root)];
  }

  void RememberLastJsObjectId();
  SnapshotObjectId max_snapshot_js_object_id() const { return max_object_id; }

 private:
  const char* GetSubRootName(Root root);
  void AddRootEntry();
  void AddSubRootEntry(Root root);

  std::deque<HeapEntry> entries_;         // all node
  std::deque<HeapGraphEdge> edges_;       // all edges
  std::vector<HeapGraphEdge*> children_;  // all edges by sort
  std::unordered_map<SnapshotObjectId, HeapEntry*> entries_by_id_cache_;

  HeapProfiler* profiler_ = nullptr;
  HeapEntry* root_entry_ = nullptr;
  HeapEntry* subroot_entries_[static_cast<uint32_t>(
      Root::kNumberOfRoots)];  // include string, context, global_object_,

  SnapshotObjectId max_object_id = 0;
};

}  // namespace heapprofiler
}  // namespace quickjs

#endif