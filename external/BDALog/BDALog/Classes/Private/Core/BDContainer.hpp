//
//  BDContainer.hpp
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDContainer_hpp
#define BDContainer_hpp

#include <stdio.h>
#include <string.h>

namespace BDALog {

enum class SeekType {
    kSeekStart,
    kSeekCur,
    kSeekEnd,
};

//固定大小的数据存储
class BDContainer final {
  public:
    BDContainer();
    BDContainer(void* data, size_t len, size_t maxlen);
    ~BDContainer();
    
    BDContainer(const BDContainer& rhs) = delete;
    BDContainer& operator=(const BDContainer& rhs) = delete;

    void Init(void* buffer_ptr, size_t len);
    void Init(void* buffer_ptr, size_t len, size_t maxlen);
    
    bool ClearDataIfNeed();
    void Reset();
    
    void Write(const void* data, size_t len);
    //This Write must be used with SetPosAndLength
    bool Write(const void* data, size_t len, off_t cur_pos);
    void SetPosAndLength(off_t pos, size_t length);

    void* GetFullData() { return data_; }
    void* GetCurrentData() { return static_cast<unsigned char*>(data_) + pos_; }
    size_t GetLength() const { return length_; }
    size_t GetMaxLength() const { return max_length_; }

  private:
    void Seek(off_t offset, SeekType type = SeekType::kSeekCur);
    
    unsigned char* data_; //weak
    off_t pos_;
    size_t length_;
    size_t max_length_;
};

}


#endif /* BDPointer_hpp */
