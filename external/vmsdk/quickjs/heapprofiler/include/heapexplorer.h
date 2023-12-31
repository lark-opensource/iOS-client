#ifndef QUICKJS_HEAP_SNAPSHOT_HEAPEXPLORER_H_
#define QUICKJS_HEAP_SNAPSHOT_HEAPEXPLORER_H_

#include "quickjs/heapprofiler/include/snapshot.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

#include <unordered_set>

struct LEPUSString;
struct LEPUSAsyncFunctionData;
struct LEPUSShape;
struct LEPUSVarRef;

namespace quickjs {
namespace heapprofiler {

class HeapSnapshotGenerator;
class HeapObjectIdMaps;
class HeapEntriesAllocator {
 public:
  virtual ~HeapEntriesAllocator() = default;
  virtual HeapEntry* AllocateEntry(const LEPUSValue& value) = 0;
};

class QjsHeapExplorer : public HeapEntriesAllocator {
 public:
  QjsHeapExplorer(HeapSnapshot* snapshot, LEPUSContext* ctx);
  virtual ~QjsHeapExplorer() override;
  QjsHeapExplorer(const QjsHeapExplorer&) = delete;
  QjsHeapExplorer& operator=(const QjsHeapExplorer&) = delete;

  HeapEntry* AllocateEntry(const LEPUSValue& value) override {
    return AddEntry(value);
  }

  void IterateAndExtractReference(HeapSnapshotGenerator* generator);

 private:
  bool HasEntry(const LEPUSValue& value) {
    int64_t tag = LEPUS_VALUE_GET_TAG(value);
    // return !(tag == LEPUS_TAG_ASYNC_FUNCTION || tag == LEPUS_TAG_MODULE ||
    //          (tag > LEPUS_TAG_INT && tag <= LEPUS_TAG_EXCEPTION));
    return (LEPUS_VALUE_HAS_REF_COUNT(value) &&
            (tag != LEPUS_TAG_ASYNC_FUNCTION) && (tag != LEPUS_TAG_MODULE)) ||
           (tag == LEPUS_TAG_INT) || (tag == LEPUS_TAG_LEPUS_CPOINTER) ||
           (tag == LEPUS_TAG_FLOAT64);
  };
  // used for a new object(node)
  HeapEntry* GetEntry(const LEPUSValue&);

  HeapEntry* AddEntry(const LEPUSValue&);
  HeapEntry* AddEntry(const LEPUSValue& value, HeapEntry::Type type,
                      const char* name, size_t size);
  HeapEntry* AddEntry(const LEPUSValue&, HeapEntry::Type, const std::string&,
                      size_t size);

  void SetInternalReference(HeapEntry* parent_entry, const char* name,
                            const LEPUSValue& child);

  void SetInternalReference(HeapEntry* parent_entry, const std::string& name,
                            const LEPUSValue& child);

  void SetElementReference(HeapEntry* parent_entry, uint32_t index,
                           const LEPUSValue& child);  // for array

  void SetPropertyReference(HeapEntry* parent_entry, LEPUSAtom name,
                            const LEPUSValue& child);

  void SetPropertyReference(HeapEntry* parenty_entry, const char* name,
                            const LEPUSValue& child);

  void SetPropertyReference(HeapEntry* parenty_entry, const std::string& name,
                            const LEPUSValue& child);

  void ExtractReference(HeapEntry* entry, const LEPUSValue& object);

  void SetRootToSubRootsReference();
  void SetSubRootReference(Root root, const LEPUSValue& value);

  void SetAtomStringRootReference();
  void SetObjectRootReference();

  void SetGlobalRootReference();

  void ExtractObjectReference(LEPUSObject* p);

  void ExtractLepusValueReference(const LEPUSValue& value);

  bool HasBeExtractted(const LEPUSValue& value) {
    if (!HasEntry(value)) return true;

    return !(has_extractedobj_.find(LEPUS_VALUE_GET_PTR(value)) ==
             has_extractedobj_.end());
  }

  bool NeedExtracted(const LEPUSValue& value) {
    return LEPUS_VALUE_HAS_REF_COUNT(value) && !HasBeExtractted(value);
  }

  void InsertExtractedObj(const LEPUSValue& value) {
    has_extractedobj_.emplace(LEPUS_VALUE_GET_PTR(value));
  }

  HeapSnapshot* snapshot_;
  LEPUSContext* context_;
  HeapSnapshotGenerator* generator_ = nullptr;
  HeapObjectIdMaps* object_id_maps_ = nullptr;

  std::unordered_set<HeapPtr> has_extractedobj_;

  static constexpr uint32_t atom_tag_int = 1U << 31;
};

}  // namespace heapprofiler
}  // namespace quickjs

#endif