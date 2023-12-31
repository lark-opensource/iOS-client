#include "quickjs/heapprofiler/include/snapshot.h"

#include <assert.h>

#include "quickjs/heapprofiler/include/gen.h"
#include "quickjs/heapprofiler/include/heapprofiler.h"

namespace quickjs {

namespace heapprofiler {

HeapEntry* HeapSnapshot::GetEntryById(SnapshotObjectId id) {
  if (entries_by_id_cache_.empty()) {
    entries_by_id_cache_.reserve(entries_.size());
    for (auto& entry : entries_) {
      entries_by_id_cache_.emplace(entry.id(), &entry);
    }
  }
  auto it = entries_by_id_cache_.find(id);
  return it != entries_by_id_cache_.end() ? it->second : nullptr;
}

void HeapSnapshot::RememberLastJsObjectId() {
  max_object_id = profiler_->object_id_maps()->LastAssignedId();
}

void HeapSnapshot::Delete() { profiler_->RemoveSnapshot(this); }

HeapEntry* HeapSnapshot::AddEntry(HeapEntry::Type type, const char* name,
                                  SnapshotObjectId id, size_t size) {
  entries_.emplace_back(this, static_cast<uint32_t>(entries().size()), type,
                        name, id, size);
  return &entries_.back();
}

HeapEntry* HeapSnapshot::AddEntry(HeapEntry::Type type, const std::string& name,
                                  SnapshotObjectId id, size_t size) {
  entries_.emplace_back(this, static_cast<uint32_t>(entries().size()), type,
                        name, id, size);
  return &entries_.back();
}

void HeapSnapshot::FillChildren() {
  uint32_t children_index = 0;
  for (auto& entry : entries_) {
    children_index = entry.set_chiledren_index(children_index);
  }
  assert(edges_.size() == static_cast<size_t>(children_index));
  children_.resize(edges_.size());

  for (auto& edge : edges_) {
    edge.from()->add_child(&edge);
  }
}

void HeapSnapshot::AddSyntheticRootEntries() {
  AddRootEntry();
  for (uint32_t i = 0; i < static_cast<uint32_t>(Root::kNumberOfRoots); ++i) {
    AddSubRootEntry(static_cast<Root>(i));
  }
}

const char* HeapSnapshot::GetSubRootName(Root root) {
  switch (root) {
#define ROOT_CASE(root_id, description) \
  case Root::root_id:                   \
    return description;
    ROOT_ID_LIST(ROOT_CASE);
#undef ROOT_CASE
    case Root::kNumberOfRoots:
      break;
  }
  return nullptr;
}

void HeapSnapshot::AddRootEntry() {
  root_entry_ =
      AddEntry(HeapEntry::kSynthetic, "", HeapObjectIdMaps::kRootEntryId, 0);
}

void HeapSnapshot::AddSubRootEntry(Root root) {
  subroot_entries_[static_cast<uint32_t>(root)] = AddEntry(
      HeapEntry::kSynthetic, GetSubRootName(root),
      HeapObjectIdMaps::SyntheicEntryId[static_cast<uint32_t>(root)], 0);
}

}  // namespace heapprofiler
}  // namespace quickjs
