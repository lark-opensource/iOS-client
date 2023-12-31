#ifndef QUICKJS_HEAP_SNAPSHOT_ENTRY_H_
#define QUICKJS_HEAP_SNAPSHOT_ENTRY_H_

#include <vector>

#include "quickjs/heapprofiler/include/edge.h"

namespace quickjs {
namespace heapprofiler {

class HeapSnapshot;
class HeapGraphEdge;
using SnapshotObjectId = uint64_t;
using HeapPtr = void*;

class HeapEntry {
 public:
  enum Type {
    kHidden = 0,            // Hidden node, may be filtered when shown to user.
    kArray = 1,             // An array of elements.
    kString = 2,            // A string.
    kObject = 3,            // A JS object (except for arrays and strings).
    kFunctionByteCode = 4,  // Compiled code.
    kVarRef = 5,            // Function closure.
    kRegExp = 6,            // RegExp.
    kHeapNumber = 7,        // Number stored in the heap.
    kCpointer = 8,          // Native object (not from V8 heap).
    kSynthetic = 9,         // Synthetic object, usually used for grouping
                            // snapshot items together.
    kConsString = 10,    // Concatenated string. A pair of pointers to strings.
    kSlicedString = 11,  // Sliced string. A fragment of another string.
    kSymbol = 12,        // A Symbol (ES6).
    kBigInt = 13,        // BigInt.
    kObjectShape = 14,   // Internal data used for tracking the shapes (or
                         // "hidden classes") of JS objects.
  };

  HeapEntry(HeapSnapshot* snapshot, uint32_t index, Type type, const char* name,
            SnapshotObjectId id, size_t self_size);

  HeapEntry(HeapSnapshot* snapshot, uint32_t index, Type type,
            const std::string& name, SnapshotObjectId id, size_t self_size);

  HeapSnapshot* snapshot() { return snapshot_; }
  Type type() const { return static_cast<Type>(type_); }

  void set_type(Type type) { type_ = type; }
  const std::string& name() const { return name_; }
  void set_name(const char* name) { name_ = name; }
  void set_name(const std::string& name) { name_ = name; }

  SnapshotObjectId id() const { return id_; }

  size_t self_size() const { return self_size_; }

  uint32_t index() const { return index_; }

  // return all edges's count from the entry
  uint32_t children_count() const;

  // set chiledren_end_index according edges's count
  uint32_t set_chiledren_index(uint32_t index);

  void add_child(HeapGraphEdge* edge);

  // return the i edge from this node
  HeapGraphEdge* child(uint32_t i);

  void SetIndexedReference(HeapGraphEdge::Type type, uint32_t index,
                           HeapEntry* entry);
  void SetNamedReference(HeapGraphEdge::Type type, const char* name,
                         HeapEntry* entry);
  void SetNamedReference(HeapGraphEdge::Type type, const std::string& name,
                         HeapEntry* entry);

  void SetIndexedAutoIndexReference(HeapGraphEdge::Type type, HeapEntry* child);

 private:
  // return edge from this node
  force_inline std::vector<HeapGraphEdge*>::iterator children_begin() const;

  force_inline std::vector<HeapGraphEdge*>::iterator children_end() const;

  uint32_t type_ : 4;
  uint32_t index_ : 28;

  // constructor name
  // example Array() Array, Object, Object()

  std::string name_;

  union {
    uint32_t children_count_;
    uint32_t children_end_index_;
  };
  HeapSnapshot* snapshot_;
  size_t self_size_;

  SnapshotObjectId id_;
};

}  // namespace heapprofiler
}  // namespace quickjs

#endif