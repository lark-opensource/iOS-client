
#include "quickjs/heapprofiler/include/edge.h"

#include "quickjs/heapprofiler/include/entry.h"
#include "quickjs/heapprofiler/include/snapshot.h"

namespace quickjs {

namespace heapprofiler {

HeapGraphEdge::HeapGraphEdge(Type type, const char* name, HeapEntry* from,
                             HeapEntry* to)
    : name_(name),
      to_entry_(to),
      bit_filed_((static_cast<uint32_t>(type)) |
                 ((static_cast<uint32_t>(from->index())) << kEdegeTypeSize)),
      is_index_or_name_(false) {}

HeapGraphEdge::HeapGraphEdge(Type type, const std::string& name,
                             HeapEntry* from, HeapEntry* to)
    : name_(name),
      to_entry_(to),
      bit_filed_((static_cast<uint32_t>(type)) |
                 ((static_cast<uint32_t>(from->index())) << kEdegeTypeSize)),
      is_index_or_name_(false) {}

HeapGraphEdge::HeapGraphEdge(Type type, uint32_t index, HeapEntry* from,
                             HeapEntry* to)
    : index_(index),
      to_entry_(to),
      bit_filed_((static_cast<uint32_t>(type)) |
                 ((static_cast<uint32_t>(from->index())) << kEdegeTypeSize)),
      is_index_or_name_(true) {}

HeapEntry* HeapGraphEdge::from() const {
  return &(snapshot()->entries()[from_index()]);
}

HeapSnapshot* HeapGraphEdge::snapshot() const { return to_entry_->snapshot(); }

}  // namespace heapprofiler
}  // namespace quickjs
