#include "base/io_buffer.h"

namespace lynx {
namespace base {
IOBuffer::IOBuffer(size_t size) { data_ = new char[size]; }

IOBuffer::~IOBuffer() {
  if (data_) {
    delete[] data_;
  }
  data_ = nullptr;
}

IOBufferWithSize::IOBufferWithSize(size_t size) : IOBuffer(size), size_(size) {}

GrowableIOBuffer::GrowableIOBuffer() : capacity_(0), offset_(0) {}

void GrowableIOBuffer::SetCapacity(size_t capacity) {
  // realloc will crash if it fails.
  real_data_.reset(static_cast<char*>(realloc(real_data_.release(), capacity)));
  capacity_ = capacity;
  if (offset_ > capacity)
    set_offset(capacity);
  else
    set_offset(offset_);  // The pointer may have changed.
}

void GrowableIOBuffer::set_offset(size_t offset) {
  offset_ = offset;
  data_ = real_data_.get() + offset;
}

size_t GrowableIOBuffer::RemainingCapacity() {
  return capacity_ >= offset_ ? capacity_ - offset_ : 0;
}

char* GrowableIOBuffer::StartOfBuffer() { return real_data_.get(); }

GrowableIOBuffer::~GrowableIOBuffer() { data_ = nullptr; }
}  // namespace base
}  // namespace lynx
