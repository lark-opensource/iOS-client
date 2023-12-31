#ifndef LYNX_BASE_IO_BUFFER_H_
#define LYNX_BASE_IO_BUFFER_H_

#include <memory>
#include <string>

#include "base/ref_counted_ptr.h"

namespace lynx {
namespace base {
class IOBuffer : public base::RefCountPtr<IOBuffer> {
 public:
  explicit IOBuffer(size_t size);
  IOBuffer() = default;
  virtual ~IOBuffer();
  char* data() { return data_; }

 protected:
  explicit IOBuffer(char* data) : data_(data) {}
  char* data_ = nullptr;
};

class IOBufferWithSize : public IOBuffer {
 public:
  explicit IOBufferWithSize(size_t size);
  virtual ~IOBufferWithSize() {}

  size_t size() const { return size_; }

 protected:
  size_t size_;
};

class StringIOBuffer : public IOBuffer {
 public:
  explicit StringIOBuffer(const std::string& s)
      : IOBuffer(static_cast<char*>(NULL)), string_data_(s) {
    data_ = const_cast<char*>(string_data_.data());
  }

  virtual ~StringIOBuffer() { data_ = nullptr; }

  int size() const { return static_cast<int>(string_data_.size()); }

 private:
  std::string string_data_;
};

class DrainableIOBuffer : public IOBuffer {
 public:
  DrainableIOBuffer(IOBuffer* base, int size)
      : IOBuffer(base->data()), base_(base), size_(size), used_(0) {}

  virtual ~DrainableIOBuffer() { data_ = nullptr; }

  void DidConsume(int bytes) {
    used_ += bytes;
    data_ = base_->data() + used_;
  }

  int BytesRemaining() { return size_ - used_; }

  int BytesConsumed() { return used_; }

 private:
  base::ScopedRefPtr<IOBuffer> base_;

  int size_;
  int used_;
};

class GrowableIOBuffer : public IOBuffer {
 public:
  GrowableIOBuffer();

  // realloc memory to the specified capacity.
  void SetCapacity(size_t capacity);
  size_t capacity() { return capacity_; }

  // |offset| moves the |data_| pointer, allowing "seeking" in the data.
  void set_offset(size_t offset);
  size_t offset() { return offset_; }

  size_t RemainingCapacity();
  char* StartOfBuffer();

 private:
  ~GrowableIOBuffer() override;

  std::unique_ptr<char[]> real_data_;
  size_t capacity_;
  size_t offset_;
};
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_IO_BUFFER_H_
