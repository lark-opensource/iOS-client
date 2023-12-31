//
//  BDALogBufferBlock.h
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDALogBufferBlock_h
#define BDALogBufferBlock_h

#include <sys/types.h>
#include <string.h>

//可拓展的数据存储
class BDALogBufferBlock final {
  public:
    enum class SeekType {
        Start,
        Cur,
        End,
    };

  public:
    explicit BDALogBufferBlock(size_t unit_size = 128);
    ~BDALogBufferBlock();
    
    BDALogBufferBlock(const BDALogBufferBlock& rhs) = delete;
    BDALogBufferBlock& operator = (const BDALogBufferBlock& rhs) = delete;
    BDALogBufferBlock(const BDALogBufferBlock&&);

    bool AllowWrite(size_t ready2write);
    bool AddCapacity(size_t size);

    void Write(const void* data, size_t data_len);

    void* Data(off_t offset = 0) { return data_ + offset; }
    void* PosPtr() { return data_ + pos_; }
    const void* Ptr(off_t offset = 0) const { return data_ + offset; }
    const void* PosPtr() const { return data_ + pos_; }

    size_t Length() const { return length_; }
    
  private:
    void Reset();
    bool Write(const off_t& _pos, const void* _new_data, size_t _new_data_len);
    void Seek(off_t _offset, SeekType _type);
    bool FitSize(size_t _len);

  private:
    unsigned char* data_ = nullptr;
    off_t pos_ = 0;
    size_t length_ = 0;
    size_t capacity_ = 0;
    size_t malloc_unit_size_;
};

#endif /* BDALogBufferBlock_h */
