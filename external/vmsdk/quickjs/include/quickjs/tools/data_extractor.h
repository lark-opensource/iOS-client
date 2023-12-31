#ifndef VMSDK_QUICKJS_TOOLS_DATAEXTRACTOR_H
#define VMSDK_QUICKJS_TOOLS_DATAEXTRACTOR_H

#include "quickjs/tools/data_buffer.h"
#include "quickjs/tools/status.h"

namespace quickjs {
namespace bytecode {

class DataExtract {
 public:
  DataExtract(const DataBuffer &DS) : DS(DS), offset(0) {}

  Status getUInt32(uint32_t &result) {
    uint32_t value = *(uint32_t *)(DS.getRawData() + offset);
    offset += sizeof(uint32_t);
    if (!isValid())
      return Status(
          ERR_HEAPOVERFLOW,
          "can not read uint32_t, it might cause heap buffer overflow");

    result = value;
    return Status::OK();
  }

  Status getString(uint32_t size, std::string &result) {
    const char *ptr =
        (reinterpret_cast<const char *>(DS.getRawData()) + offset);
    offset += size + 1;
    if (!isValid())
      return Status(ERR_HEAPOVERFLOW,
                    "can not read string, it might cause heap buffer overflow");

    result = std::string(ptr, size);
    return Status::OK();
  }

  bool isValid() const { return offset <= DS.getActualSize(); }

 private:
  const DataBuffer &DS;
  uint32_t offset;
};

}  // namespace bytecode
}  // namespace quickjs

#endif
