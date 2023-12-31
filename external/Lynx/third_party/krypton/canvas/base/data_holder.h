// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef CANVAS_BASE_DATA_HOLDER_H_
#define CANVAS_BASE_DATA_HOLDER_H_

#include <cstdint>
#include <functional>
#include <memory>

#include "base/base_export.h"

namespace lynx {
namespace canvas {
class DataHolder {
 public:
  typedef void (*ReleaseProc)(const void *ptr, void *context);

  static std::unique_ptr<DataHolder> MakeWithReleaseProc(
      const void *data, size_t size, void *context, ReleaseProc releaseProc);

  static std::unique_ptr<DataHolder> MakeWithoutCopy(const void *data,
                                                     size_t size);
  static std::unique_ptr<DataHolder> MakeWithCopy(const void *data,
                                                  size_t size);
  BASE_EXPORT static std::unique_ptr<DataHolder> MakeWithMalloc(size_t size);
  static std::unique_ptr<DataHolder> MakeWithMoveTo(const void *data,
                                                    size_t size);

  static DataHolder MakeWithCopyOnStack(const void *data, size_t size);

  const void *Data() const { return data_ptr_; }

  void *Release();

  void *WritableData() const { return const_cast<void *>(data_ptr_); }

  size_t Size() const { return size_; }

  DataHolder(const DataHolder &) = delete;
  DataHolder(DataHolder &&);
  BASE_EXPORT ~DataHolder();

  DataHolder &operator=(const DataHolder &) = delete;

 private:
  DataHolder(const void *data_ptr, size_t size, ReleaseProc release_proc);

  DataHolder(const void *data_ptr, size_t size, void *context,
             ReleaseProc release_proc);
  const void *data_ptr_;
  size_t size_;
  void *context_ = NULL;
  ReleaseProc release_proc_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // CANVAS_BASE_DATA_HOLDER_H_
