// Copyright 2022 The Lynx Authors. All rights reserved.

#include "aurum/loader/platform_loader.h"

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <new>

#include "aurum/loader.h"
#include "canvas/base/log.h"
#ifdef OS_ANDROID
#include <endian.h>
#endif

namespace lynx {
namespace canvas {
namespace au {

class PlatformLoader : public LoaderBase {
 public:
  class Delegate : PlatformLoaderDelegate {
   public:
    virtual ~Delegate() = default;
    void OnStart(int64_t content_length) override {
      if (loader_ref_) {
        loader_ref_->OnStart(content_length);
      }
    }
    void OnData(const void *data, uint64_t len) override {
      if (loader_ref_) {
        loader_ref_->OnData(data, len);
      }
    }
    void OnEnd(bool success, const char *err_msg) override {
      if (loader_ref_) {
        loader_ref_->OnEnd(success, err_msg);
      }
      delete this;
    }
    void UnRef() { loader_ref_ = nullptr; }
    void Ref(PlatformLoader *loader) { loader_ref_ = loader; }

   private:
    PlatformLoader *loader_ref_ = nullptr;
  } *delegate = nullptr;

  class ScopedLock {
   public:
    ScopedLock(int &lock) : lock_(lock) { AU_LOCK(lock_); }
    ~ScopedLock() { AU_UNLOCK(lock_); }

   private:
    int &lock_;
  };

  inline PlatformLoader(const char *path, Delegate *d) : delegate(d) {
    KRYPTON_LOGV("new PlatformLoader ") << sizeof(PlatformLoader);
    if (delegate) {
      delegate->Ref(this);
    }
  }

  virtual LoadResult Read(size_t start, size_t end, LoaderData &data) override {
    ScopedLock auto_lock(buf_lock_);

    if (error_) {
      return LoadResult::EndOfFile;
    }

    if (!data_.Data()) {
      return LoadResult::Pending;
    }

    if (total_content_length_ >= 0 && ssize_t(end) > total_content_length_) {
      return LoadResult::EndOfFile;
    }

    if (end > data_.DataLength()) {
      return LoadResult::Pending;
    }

    data = data_;

    return LoadResult::OK;
  }

  virtual ~PlatformLoader() {
    ScopedLock auto_lock(buf_lock_);

    if (delegate) {
      delegate->UnRef();
      // do not delete
    }
  }

  void OnStart(int64_t length) {
    ScopedLock auto_lock(buf_lock_);
    if (length >= 0) {
      total_content_length_ = length;
    } else {
      total_content_length_ = -1;
    }
  }

  void OnEnd(bool success, const char *err_msg) {
    ScopedLock auto_lock(buf_lock_);
    total_content_length_ = data_.DataLength();
    if (!success) {
      error_ = true;
    }
    if (delegate) {
      delegate->UnRef();
      // do not delete
      delegate = nullptr;
    }
  }

  void OnData(const void *data, uint64_t length) {
    ScopedLock auto_lock(buf_lock_);
    if (error_) {
      return;
    }

    KRYPTON_LOGV("OnData: ") << data_.DataLength() << " + " << length << " , "
                             << total_content_length_ << "total";

    uint64_t required = length + data_.DataLength();
    uint64_t buffer_length = data_.BufferLength();

    if (required > buffer_length) {
      if (!buffer_length) {
        if (total_content_length_ < 0) {
          // wav:predicted size
          const uint32_t *ints = static_cast<const uint32_t *>(data);
          if (ints[0] == htonl('RIFF')) {
            buffer_length = ints[1] + 8;
          } else {
            buffer_length = 262144;  // 256KB
          }
        } else {
          buffer_length = uint32_t(total_content_length_);
        }
      }
      while (buffer_length < required) {
        buffer_length <<= 1;
      }
      // There may be a case where the decoder accesses the memory in another
      // thread and the buffer is removed To avoid this:
      // 1. Let the upper layer return content as much as possible length
      // instead of streaming response
      // 2. Increase the buffer size to reduce the trigger probability and pre
      // judgment size
      LoaderData new_data;
      new_data.AllocBuffer(buffer_length);
      if (data_.DataLength()) {
        new_data.FillBuffer(0, data_.Data(), data_.DataLength());
      }
      data_ = new_data;
    }

    data_.FillBuffer(data_.DataLength(), data, length);
  }

 private:
  bool error_ = false;
  int buf_lock_ = 0;
};

void loader::Platform(LoaderBase *base, const char *path, void **delegate) {
  auto local_delegate = new PlatformLoader::Delegate();

  new (base) PlatformLoader(path, local_delegate);

  if (delegate) {
    *delegate = local_delegate;
  }
}

}  // namespace au
}  // namespace canvas
}  // namespace lynx
