#ifndef QUICKJS_HEAP_SNAPSHOT_EDGE_H_
#define QUICKJS_HEAP_SNAPSHOT_EDGE_H_

#include <string>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/cutils.h"

#ifdef __cplusplus
}
#endif

namespace quickjs {
namespace heapprofiler {

class HeapEntry;
class HeapSnapshot;

#define ROOT_ID_LIST(V)                       \
  V(kLEPUSContextList, "(LEPUSContextLists)") \
  V(kLepusString, "(AtomString)")             \
  V(kLepusObject, "(LEPUSObjects)")           \
  V(kGlobalObject, "(GlobalObject)")

enum class Root {
#define DECLARE_ENUM(enum_item, ignore) enum_item,
  ROOT_ID_LIST(DECLARE_ENUM)
#undef DECLARE_ENUM
      kNumberOfRoots
};

class HeapGraphEdge {
 public:
  enum Type {
    kContextVariable = 0,  // A variable from a function context.
    kElement = 1,          // An element of an array.
    kProperty = 2,         // A named object property.
    kInternal = 3,         // A link that can't be accessed from JS,
                           // thus, its name isn't a real property name
                           // (e.g. parts of a ConsString).
    kHidden = 4,           // A link that is needed for proper sizes
                           // calculation, but may be hidden from user.
    kShortcut = 5,         // A link that must not be followed during
                           // sizes calculation.
    kWeak = 6              // A weak reference (ignored by the GC).
  };

  static constexpr uint32_t kFromEntrySize = 29;
  static constexpr uint32_t kEdegeTypeSize = 3;
  static constexpr uint32_t kTypeMask = (1 << kEdegeTypeSize) - 1;
  static constexpr uint32_t kFromeEntryMask =
      (((uint64_t)1 << 32) - (1 << kEdegeTypeSize));

  HeapGraphEdge(Type type, const char* name, HeapEntry* from, HeapEntry* to);
  HeapGraphEdge(Type type, uint32_t index, HeapEntry* from, HeapEntry* to);
  HeapGraphEdge(Type type, const std::string& name, HeapEntry* from,
                HeapEntry* to);

  Type type() const { return static_cast<Type>(bit_filed_ & kTypeMask); }

  uint32_t index() const { return index_; }

  const std::string& name() const { return name_; }

  HeapEntry* from() const;
  HeapEntry* to() const { return to_entry_; }

  bool IsIndex() const { return is_index_or_name_; }

 private:
  force_inline HeapSnapshot* snapshot() const;
  // |-from_entry_index-|type|
  // |-------29bit------|3bit|
  uint32_t from_index() const {
    return (bit_filed_ & kFromeEntryMask) >> kEdegeTypeSize;
  }

  uint32_t index_;
  std::string name_;
  // index -> true, name -> false

  HeapEntry* to_entry_;
  uint32_t bit_filed_;
  bool is_index_or_name_;
};

}  // namespace heapprofiler
}  // namespace quickjs

#endif