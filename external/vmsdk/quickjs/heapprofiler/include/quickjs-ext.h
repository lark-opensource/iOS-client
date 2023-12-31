#ifndef QUICKJS_DEBUGGER_QUICKJS_EXT_H_
#define QUICKJS_DEBUGGER_QUICKJS_EXT_H_

#include <string>
#include <vector>

#include "quickjs/heapprofiler/include/entry.h"
#include "quickjs/heapprofiler/include/heapexplorer.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"

#ifdef __cplusplus
}
#endif

class EntryInfo {
 public:
  EntryInfo() {}

  EntryInfo(const EntryInfo& info) {
    name_ = info.name_;
    size_ = info.size_;
    type_ = info.type_;
  }

  EntryInfo(EntryInfo&& info) {
    name_ = std::move(info.name_);
    size_ = info.size_;
    type_ = info.type_;
  }

  EntryInfo& operator=(const EntryInfo& info) {
    if (this == &info) return *this;
    name_ = info.name_;
    size_ = info.size_;
    type_ = info.type_;
    return *this;
  }

  EntryInfo& operator=(EntryInfo&& info) {
    if (this == &info) {
      return *this;
    }
    name_ = std::move(info.name_);
    size_ = info.size_;
    type_ = info.type_;
    return *this;
    ;
  }

  std::string name_;
  size_t size_;
  quickjs::heapprofiler::HeapEntry::Type type_;
};

EntryInfo GetNameAndComputeSize(LEPUSContext* ctx, const LEPUSValue& value);

extern LEPUSValue GetGlobalVarObj(LEPUSContext* ctx);

#endif