// Copyright 2021 The Lynx Authors. All rights reserved.

#include "data_holder.h"

#include "canvas/base/log.h"

namespace lynx {
namespace canvas {
namespace {
void NopReleaseProc(const void *, void *) {}
}  // namespace
std::unique_ptr<DataHolder> DataHolder::MakeWithoutCopy(const void *data,
                                                        size_t size) {
  return std::unique_ptr<DataHolder>(
      new DataHolder(data, size, NopReleaseProc));
}

std::unique_ptr<DataHolder> DataHolder::MakeWithCopy(const void *data,
                                                     size_t size) {
  if (!size) {
    //    KRYPTON_DLOGI("DataHolder MakeWithCopy with size 0 and ptr ") << data;
    return std::unique_ptr<DataHolder>(
        new DataHolder(nullptr, 0, NopReleaseProc));
  }
  void *data_ptr = std::malloc(size);
  DCHECK(data_ptr);
  if (data && data_ptr) {
    std::memcpy(data_ptr, data, size);
  } else {
    KRYPTON_LOGI("DataHolder created with invalid ptr, data is  ")
        << data << " data_ptr is " << data_ptr << " size is " << size;
  }

  return std::unique_ptr<DataHolder>(
      new DataHolder(data_ptr, size, [](const void *data_ptr, void *context) {
        std::free(const_cast<void *>(data_ptr));
      }));
}

std::unique_ptr<DataHolder> DataHolder::MakeWithMalloc(size_t size) {
  if (!size) {
    //    KRYPTON_DLOGI("DataHolder MakeWithMalloc with size 0");
    return std::unique_ptr<DataHolder>(
        new DataHolder(nullptr, 0, NopReleaseProc));
  }
  void *data_ptr = std::malloc(size);
  DCHECK(data_ptr);
  if (data_ptr) {
    memset(data_ptr, 0, size);
  } else {
    KRYPTON_LOGI(
        "DataHolder created with invalid size or malloc return null, dataptr "
        "is  ")
        << data_ptr << " size is " << size;
  }

  return std::unique_ptr<DataHolder>(
      new DataHolder(data_ptr, size, [](const void *data_ptr, void *context) {
        std::free(const_cast<void *>(data_ptr));
      }));
}

DataHolder DataHolder::MakeWithCopyOnStack(const void *data, size_t size) {
  if (!size) {
    //    KRYPTON_DLOGI("DataHolder MakeWithCopyOnStack with size 0");
    return DataHolder(nullptr, 0, NopReleaseProc);
  }
  void *data_ptr = std::malloc(size);
  DCHECK(data_ptr);
  if (data && data_ptr) {
    std::memcpy(data_ptr, data, size);
  } else {
    KRYPTON_LOGI("DataHolder created with invalid ptr, data is  ")
        << data << " data_ptr is " << data_ptr << " size is " << size;
  }
  return DataHolder(data_ptr, size, [](const void *data_ptr, void *context) {
    std::free(const_cast<void *>(data_ptr));
  });
}

std::unique_ptr<DataHolder> DataHolder::MakeWithMoveTo(const void *data,
                                                       size_t size) {
  return std::unique_ptr<DataHolder>(
      new DataHolder(data, size, [](const void *data_ptr, void *context) {
        std::free(const_cast<void *>(data_ptr));
      }));
}

std::unique_ptr<DataHolder> DataHolder::MakeWithReleaseProc(
    const void *data, size_t size, void *context, ReleaseProc releaseProc) {
  return std::unique_ptr<DataHolder>(
      new DataHolder(data, size, context, releaseProc));
}

DataHolder::DataHolder(const void *data_ptr, size_t size,
                       ReleaseProc release_proc)
    : DataHolder(data_ptr, size, NULL, release_proc) {}

DataHolder::DataHolder(const void *data_ptr, size_t size, void *context,
                       ReleaseProc release_proc)
    : data_ptr_(data_ptr),
      size_(size),
      context_(context),
      release_proc_(release_proc) {}

DataHolder::~DataHolder() {
  if (release_proc_) {
    release_proc_(data_ptr_, context_);
  }
}

DataHolder::DataHolder(DataHolder &&origin)
    : data_ptr_(origin.data_ptr_),
      size_(origin.size_),
      release_proc_(origin.release_proc_) {
  origin.data_ptr_ = nullptr;
  origin.size_ = 0;
  origin.release_proc_ = nullptr;
}

void *DataHolder::Release() {
  void *ptr = const_cast<void *>(data_ptr_);
  data_ptr_ = nullptr;
  release_proc_ = nullptr;
  return ptr;
}
}  // namespace canvas
}  // namespace lynx
