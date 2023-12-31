// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_DATA_REF_H_
#define LYNX_STARLIGHT_STYLE_DATA_REF_H_

#include "base/ref_counted.h"

namespace lynx {
namespace starlight {

template <typename T>
class DataRef {
 public:
  const T* Get() const { return data_.Get(); }
  static_assert(std::is_same_v<decltype(&DataRef::Get),
                               const T* (DataRef<T>::*)() const>);

  const T& operator*() const { return *Get(); }
  const T* operator->() const { return Get(); }

  T* Access() {
    if (!data_->HasOneRef()) {
      data_ = data_->Copy();
    }
    return data_.Get();
  }

  void Init() {
    DCHECK(!data_);
    data_ = T::Create();
  }

  bool operator==(const DataRef<T>& o) const {
    DCHECK(data_);
    DCHECK(o.data_);
    return data_ == o.data_ || *data_ == *o.data_;
  }

  bool operator!=(const DataRef<T>& o) const {
    DCHECK(data_);
    DCHECK(o.data_);
    return data_ != o.data_ && *data_ != *o.data_;
  }

  void operator=(std::nullptr_t) { data_ = nullptr; }

 private:
  base::scoped_refptr<T> data_;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_DATA_REF_H_
