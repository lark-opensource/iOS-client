#ifndef __BLOB_HPP_
#define __BLOB_HPP_

#include <stdlib.h>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#define MOK 0
#define MERR_NO_MEMORY 1
#define NOT_IMPLEMENTED 2
#define MInt8 signed char
#define MInt16 short int
#define MInt32 int
#define MFloat float
#define MChar char

class SyncedMem {
 public:
  SyncedMem() : data_(nullptr), size_(0) {}
  inline void* data() { return data_; }
  inline void set_data(void* data) { data_ = data; }
  inline int32_t size() { return size_; }
  inline void set_size(int32_t size) { size_ = size; }

  ~SyncedMem() {
    if (data_ != nullptr) {
      free(data_);
      data_ = nullptr;
    }
    size_ = 0;
  }

 private:
  void* data_;
  int32_t size_;
};

/**
 Blob分为两类，内存共享和私有，当blob_index值为-1时，Blob独自占有一块内存，当blob_index为非负值的时候，blob_index指在线程全局内存中的索引值
 */
class Blob {
 public:
  explicit Blob()
      : data_memory_(), data_type_(4), fraction_length_(0), blob_index_(-1) {}

  int32_t reshape(int32_t num,
                  int32_t height,
                  int32_t width,
                  int32_t channels,
                  int32_t data_type = 4,
                  int32_t fraction_length = 0) {
    int32_t res = MOK;
    shape_.resize(4);
    shape_[0] = num_ = num;
    shape_[1] = height_ = height;
    shape_[2] = width_ = width;
    shape_[3] = channels_ = channels;
    data_type_ = data_type;
    fraction_length_ = fraction_length;
    count_ = num_ * height_ * width_ * channels_;

    if (blob_index_ == -1) {
      data_memory_.reset(new SyncedMem());
      if (data_memory_.get() == nullptr) {
        res = MERR_NO_MEMORY;
        return res;
      }
      void* data = malloc(count_ * data_type_);
      if (data == nullptr) {
        res = MERR_NO_MEMORY;
        return res;
      }
      data_memory_->set_data(data);
      data_memory_->set_size(count_ * data_type_);
    } else if (blob_index_ != -1 && count_ * data_type > data_memory_->size()) {
      if (data_memory_->data() != nullptr) {
        free(data_memory_->data());
      }
      void* data = malloc(count_ * data_type_);
      if (data == nullptr) {
        res = MERR_NO_MEMORY;
        return res;
      }
      data_memory_->set_data(data);
      data_memory_->set_size(count_ * data_type_);
    }
    return res;
  }

  inline int32_t num() { return num_; }
  inline int32_t height() { return height_; }
  inline int32_t width() { return width_; }
  inline int32_t channels() { return channels_; }
  inline int32_t count() { return count_; }
  inline void set_blob_name(const std::string& blob_name) {
    blob_name_ = blob_name;
  }
  inline const std::string& blob_name() { return blob_name_; }

  inline int32_t offset(int32_t n,
                        int32_t h = 0,
                        int32_t w = 0,
                        int32_t c = 0) {
    return ((n * height() + h) * width() + w) * channels() + c;
  }

  inline int32_t data_type() { return data_type_; }

  inline void* data() { return data_memory_->data(); }
  inline const std::vector<int32_t>& shape() const { return shape_; }
  inline int32_t fraction_length() { return fraction_length_; }
  inline int32_t blob_index() { return blob_index_; }

  inline int32_t set_blob_index(int32_t blob_index) {
    int32_t res = MOK;
    blob_index_ = blob_index;
    if (blob_index_ != -1) {
      if (blob_index_ + 1 > blob_memory_.size()) {
        blob_memory_.resize(blob_index_ + 1);
      }
      if (blob_memory_[blob_index_].get() == nullptr) {
        blob_memory_[blob_index_].reset(new SyncedMem());
        if (blob_memory_[blob_index_].get() == nullptr) {
          res = MERR_NO_MEMORY;
          return res;
        }
      }
      data_memory_ = blob_memory_[blob_index_];
    }
    return res;
  }

 private:
  Blob(const Blob& blob);
  Blob& operator=(const Blob& blob);
  int32_t num_;
  int32_t height_;
  int32_t width_;
  int32_t channels_;
  int32_t count_;
  std::string blob_name_;
  std::vector<int32_t> shape_;
  //
  int32_t data_type_;  // 1 : int8_t , 2 :  int16_t , 4 : float32_t or int32_t
  int32_t fraction_length_;
  int32_t blob_index_;
  std::shared_ptr<SyncedMem> data_memory_;
  static std::vector<std::shared_ptr<SyncedMem> > blob_memory_;
};

#endif /* blob_hpp */
