#ifndef VMSDK_QUICKJS_TOOLS_DATABUFFER_H
#define VMSDK_QUICKJS_TOOLS_DATABUFFER_H

#include <iostream>
#include <memory>
#include <string>
#include <type_traits>

namespace quickjs {
namespace bytecode {

using WriteSzAndOffsetTy = std::pair<uint32_t, uint32_t>;

class DataBuffer {
  class RawMemBuf {
   public:
    RawMemBuf() : buf(nullptr), size(0), offset(0) {}
    RawMemBuf(uint32_t size) : size(size), offset(0) {
      buf = new uint8_t[size];
      // #ifndef EMSCRIPTEN
      //       assert(buf && "failed to allocate memor");
      // #endif
      bzero(buf, size);
    }

    RawMemBuf &operator=(const std::shared_ptr<RawMemBuf> &Other) {
      // #ifndef EMSCRIPTEN
      //       assert(size >= Other->size && "size should be right");
      // #endif
      std::copy(Other->buf, Other->buf + Other->size, buf);
      size = Other->size;
      offset = Other->offset;
      return *this;
    }

    // get & set
    uint8_t *getBuf() const { return buf; }
    uint32_t getSize() const { return size; }
    uint32_t getOffset() const { return offset; }

    ~RawMemBuf() {
      if (buf) delete buf;
    }

    void resize(uint64_t newSize) {
      if (newSize <= size) return;

      // allocate memory
      uint8_t *tmp = new uint8_t[newSize];
      // #ifndef EMSCRIPTEN
      //       assert(tmp && "failed to allocate memory");
      // #endif
      bzero(tmp, newSize);
      memcpy(tmp, buf, offset);

      // set size
      size = newSize;

      delete buf;
      buf = tmp;
    }

    void grow(uint32_t newSize) {
      if (newSize > size) resize((uint32_t)(newSize * 1.5));
    }

    WriteSzAndOffsetTy writeUInt32(const uint32_t value) {
      // 1. grow if need
      grow(offset + sizeof(uint32_t));

      // 2. write uint32_t
      uint32_t curOffset = offset;
      *(uint32_t *)(buf + offset) = value;
      offset += sizeof(uint32_t);
      return std::make_pair(sizeof(uint32_t), curOffset);
    }

    WriteSzAndOffsetTy writeString(const std::string &value) {
      // 1. grow if need
      grow(offset + value.size() + 1);

      // 2. write string
      uint32_t curOffset = offset;
      memcpy((buf + offset), (const uint8_t *)value.c_str(), value.size());
      offset += value.size();
      buf[offset] = '\0';
      offset += 1;
      return std::make_pair(value.size(), curOffset);
    }

   private:
    uint8_t *buf;
    uint32_t size;
    uint32_t offset;
  };

 public:
  DataBuffer(uint32_t origSize)
      : refContent(DataBuffer::EMPTY_STR), ref(false) {
    data.reset(new RawMemBuf(origSize));
  }

  DataBuffer(const std::string &content)
      : data(nullptr), refContent(content), ref(true) {}

  inline uint64_t size() const {
    if (ref) return refContent.size();
    // #ifndef EMSCRIPTEN
    //     assert(data && "data should be not nullptr");
    // #endif
    return data->getSize();
  }

  inline const uint8_t *getRawData() const {
    if (ref) return (const uint8_t *)refContent.c_str();
    return data->getBuf();
  }
  inline uint32_t getActualSize() const {
    if (ref) return refContent.size();
    return data->getOffset();
  }
  inline std::string getStrData() const {
    if (ref) return refContent;
    return std::string(reinterpret_cast<const char *>(getRawData()),
                       getActualSize());
  }
  inline bool isRef() const { return ref; }

#undef WRITE_TEMPLATE
#define WRITE_TEMPLATE(T_STR, T)                    \
  WriteSzAndOffsetTy write##T_STR(const T &value) { \
    if (!ref) return data->write##T_STR(value);     \
    __builtin_unreachable();                        \
  }

  WRITE_TEMPLATE(UInt32, uint32_t);
  WRITE_TEMPLATE(String, std::string);

#undef WRITE_TEMPLATE

 private:
  std::shared_ptr<RawMemBuf> data;
  const std::string &refContent;
  const bool ref;

 public:
  static std::string EMPTY_STR;
};

}  // namespace bytecode
}  // namespace quickjs

#endif
