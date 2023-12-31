#include "quickjs/heapprofiler/include/heapexplorer.h"

#include <vector>

#include "quickjs/heapprofiler/include/gen.h"
#include "quickjs/heapprofiler/include/heapprofiler.h"
#include "quickjs/heapprofiler/include/quickjs-ext.h"

namespace quickjs {
namespace heapprofiler {

QjsHeapExplorer::QjsHeapExplorer(HeapSnapshot* snapshot, LEPUSContext* ctx)
    : snapshot_(snapshot),
      context_(ctx),
      object_id_maps_(snapshot->profiler()->object_id_maps()) {}

QjsHeapExplorer::~QjsHeapExplorer() {}

HeapEntry* QjsHeapExplorer::GetEntry(const LEPUSValue& value) {
  if (!HasEntry(value)) return nullptr;
  return generator_->FindOrAddEntry(value, this);
}

HeapEntry* QjsHeapExplorer::AddEntry(const LEPUSValue& value) {
  EntryInfo info = GetNameAndComputeSize(context_, value);
  return AddEntry(value, info.type_, info.name_, info.size_);
}

HeapEntry* QjsHeapExplorer::AddEntry(const LEPUSValue& value,
                                     HeapEntry::Type type, const char* name,
                                     size_t size) {
  SnapshotObjectId object_id = object_id_maps_->GetEntryObjectId(value);
  return snapshot_->AddEntry(type, name, object_id, size);
}

HeapEntry* QjsHeapExplorer::AddEntry(const LEPUSValue& value,
                                     HeapEntry::Type type,
                                     const std::string& name, size_t size) {
  SnapshotObjectId object_id = object_id_maps_->GetEntryObjectId(value);
  return snapshot_->AddEntry(type, name, object_id, size);
}

void QjsHeapExplorer::SetInternalReference(HeapEntry* parent_entry,
                                           const char* name,
                                           const LEPUSValue& child) {
  HeapEntry* child_entry = GetEntry(child);
  if (child_entry == nullptr) {
    return;
  }

  parent_entry->SetNamedReference(HeapGraphEdge::kInternal, name, child_entry);
}

void QjsHeapExplorer::SetInternalReference(HeapEntry* parent_entry,
                                           const std::string& name,
                                           const LEPUSValue& child) {
  HeapEntry* child_entry = GetEntry(child);
  if (child_entry == nullptr) {
    return;
  }

  parent_entry->SetNamedReference(HeapGraphEdge::kInternal, name, child_entry);
}

void QjsHeapExplorer::SetElementReference(HeapEntry* parent_entry,
                                          uint32_t index,
                                          const LEPUSValue& child) {
  HeapEntry* child_entry = GetEntry(child);
  if (child_entry == nullptr) {
    return;
  }
  parent_entry->SetIndexedReference(HeapGraphEdge::kElement, index,
                                    child_entry);
}

void QjsHeapExplorer::SetPropertyReference(HeapEntry* parent_entry,
                                           LEPUSAtom name,
                                           const LEPUSValue& child) {
  HeapEntry* child_entry = GetEntry(child);
  if (child_entry == nullptr) {
    return;
  }

  if (name & atom_tag_int) {
    // name is number
    parent_entry->SetIndexedReference(HeapGraphEdge::kElement,
                                      (name & ~atom_tag_int), child_entry);
    return;
  }

  const char* names = LEPUS_AtomToCString(context_, name);
  parent_entry->SetNamedReference(HeapGraphEdge::kProperty, names, child_entry);
  LEPUS_FreeCString(context_, names);
}

void QjsHeapExplorer::SetPropertyReference(HeapEntry* parenty_entry,
                                           const char* name,
                                           const LEPUSValue& child) {
  HeapEntry* child_entry = GetEntry(child);
  if (child_entry == nullptr) {
    return;
  }
  parenty_entry->SetNamedReference(HeapGraphEdge::kProperty, name, child_entry);
}

void QjsHeapExplorer::SetRootToSubRootsReference() {
  for (uint32_t i = 0; i < static_cast<uint32_t>(Root::kNumberOfRoots); ++i) {
    snapshot_->root()->SetIndexedAutoIndexReference(
        HeapGraphEdge::kElement, snapshot_->subroot(static_cast<Root>(i)));
  }
}

void QjsHeapExplorer::SetSubRootReference(Root root, const LEPUSValue& value) {
  HeapEntry* child_entry = GetEntry(value);
  if (child_entry == nullptr) return;
  snapshot_->subroot(root)->SetIndexedAutoIndexReference(
      HeapGraphEdge::Type::kElement, child_entry);
}

void QjsHeapExplorer::SetGlobalRootReference() {
  LEPUSValue global_obj = LEPUS_GetGlobalObject(context_);

  HeapEntry* global_obj_entry = GetEntry(global_obj);

  if (global_obj_entry) {
    snapshot_->subroot(Root::kGlobalObject)
        ->SetIndexedAutoIndexReference(HeapGraphEdge::kElement,
                                       global_obj_entry);
  }
  LEPUS_FreeValue(context_, global_obj);

  LEPUSValue glolbal_var_obj = GetGlobalVarObj(context_);

  HeapEntry* global_var_obj_entry = GetEntry(glolbal_var_obj);

  if (global_var_obj_entry) {
    snapshot_->subroot(Root::kGlobalObject)
        ->SetIndexedAutoIndexReference(HeapGraphEdge::kElement,
                                       global_var_obj_entry);
  }

  LEPUS_FreeValue(context_, glolbal_var_obj);
}

}  // namespace heapprofiler
}  // namespace quickjs
