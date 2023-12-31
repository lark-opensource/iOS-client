//
// Created by bytedance on 2022/7/15.
//

#ifndef SAMI_CORE_AE_CYCLE_FIFO_BUFFER_H
#define SAMI_CORE_AE_CYCLE_FIFO_BUFFER_H

#include <vector>
#include <cassert>
#include <climits>
#include "ae_math_utils.h"
#include "print2log.h"

namespace mammon {

template <typename T>
class MAMMON_EXPORT CycleFifoBufferX {
public:
    CycleFifoBufferX() {
        reallocMem(1024);
    }
    CycleFifoBufferX(size_t count) {
        reallocMem(count);
    }
    CycleFifoBufferX(CycleFifoBufferX& other) {
        size_t dataSize = other.getAvailableSize();
        if(dataSize > 0) {
            T* data = other.ptrBegin();
            if(data)write(data,dataSize);
        }else{
            reallocMem(other.getSize());
        }
    }
    ~CycleFifoBufferX() {
        clear();
        if(data_) {
            free(data_);
            data_ = 0;
        }
    }
    size_t read(T* data, size_t count) {
        assert(data);
        if(data == nullptr || count == 0) {
            return 0;
        }
        size_t realCount = count <= data_size_ ? count : data_size_;
        if(realCount > 0) {
            size_t startPos = read_ & (buffer_size_ - 1);
            size_t firstLen = realCount < (buffer_size_ - startPos) ? realCount : (buffer_size_ - startPos);
            size_t secondLen = realCount - firstLen;
            memcpy(data, data_ + startPos, firstLen * sizeof(T));
            if(secondLen > 0) {
                memcpy(data + firstLen, data_, secondLen * sizeof(T));
            }
            read_ += realCount;
            data_size_ = write_ - read_;
        }
        return realCount;
    }
    //data has been read by ptrbegin ,or we want to drop it,just update idx
    size_t fakeRead(size_t count){
        size_t len = count>data_size_?data_size_:count;
        read_+=len;
        data_size_ = write_-read_;
        return len;
    }
    size_t write(const T* data, size_t count) {
        assert(data);
        if(data == nullptr || count == 0 || reallocMem(data_size_ + count) < 0) {
            return 0;
        }
        size_t endPos = write_ & (buffer_size_ - 1);
        size_t firstLen = count < (buffer_size_ - endPos) ? count : (buffer_size_ - endPos);
        memcpy(data_ + endPos, data, firstLen * sizeof(T));
        memcpy(data_, data + firstLen, (count - firstLen) * sizeof(T));
        write_ += count;
        data_size_ = write_ - read_;
        return count;
    }
    //data has been write by ptrEnd ,just update idx
    size_t fakeWrite(size_t count){
        write_+=count;
        data_size_=write_-read_;
        return count;
    }
    void moveData(CycleFifoBufferX &_v){
        write(_v.ptrBegin(),_v.getAvailableSize());
        _v.clear();
    }
    void clear() {
        read_ = 0;
        write_ = 0;
        data_size_ = 0;
        memset(data_, 0, buffer_size_ * sizeof(T));
    }
    bool isEmpty() {
        return data_size_ == 0;
    }
    bool isFull() {
        return data_size_ == buffer_size_;
    }
    void resize(uint32_t count) {
        reallocMem(count);
    }
    //返回循环缓冲区中数据长度
    size_t getAvailableSize() const {
        return data_size_;
    }
    //返回循环缓冲区长度
    size_t getSize() const {
        return buffer_size_;
    }
    T* data() {
        return data_;  //unsafe 作为一次性临时缓冲区时可以这么用，用完要清空状态
    }
    T* ptrBegin(){
        assert(data_);
        size_t start = read_ &( buffer_size_ -1);
        size_t end = write_ &(buffer_size_ -1);
        if(end>start){
            return data_+start;
        }else{
            _moveToStart();
            return data_;
        }
    }
    T* ptrEnd(size_t writeLen){
        assert(data_);
        size_t start = read_ &( buffer_size_ -1);
        size_t end = write_ &(buffer_size_ -1);
        if(getAvailableSize()+writeLen > getSize()){
            reallocMem( getAvailableSize()+writeLen );
            return data_ + write_;
        }else{
            size_t endpos = write_ & ( buffer_size_-1);
            if( endpos +writeLen > buffer_size_){
                _moveToStart();
                return data_ + write_;
            }else{
                return data_+endpos;
            }
        }
    }
protected:
    int reallocMem(size_t count) {
        if(count <= buffer_size_) {
            return 0;
        }
        //找到最接近2的幂次方的元素容量大小
        size_t n = 0;
        size_t bcnt = sizeof(size_t) << 3;
        size_t needLen = count;
        size_t realLen = 0;
        for(size_t k = 0; k < bcnt; k++) {
            n = 1 << (bcnt - k - 1);
            if(n & needLen) {
                if(needLen > n) {
                    realLen = n << 1;
                } else {
                    realLen = n;
                }
                break;
            }
        }

        //分配新内存
        if(realLen == 0 || realLen > 0x10000000) {
            printfE("CycleFifoBufferX reallocMem wrong realLen size, realLen %ld.", realLen);
            assert(0);
            return -1;
        }
        T* data = (T*)calloc(realLen, sizeof(T));
        if(data == NULL) {
            printfE("CycleFifoBufferX reallocMem alloc mem failed.");
            return -1;
        }
        //拷贝旧数据
        if(data_size_ > 0 && data_) {
            data_size_ = read(data, data_size_);
        }

        if(data_ != NULL) {
            free(data_);
            data_ = NULL;
        }
        read_ = 0;
        write_ = data_size_;
        data_ = data;
        buffer_size_ = realLen;
        return 0;
    }
private:
    //force to move data to start from 0 position
    void _moveToStart(){
        size_t len = getAvailableSize();
        if(len>0){
            T* buf = new T[len];
            if(buf){
                this->read(buf,len);
                read_=0;write_=0;
                this->write(buf,len);
                delete[] buf;
                buf= nullptr;
            }
        }
    }
private:
    size_t read_{0};
    size_t write_{0};
    T* data_{nullptr};
    size_t buffer_size_{0};
    size_t data_size_{0};
};
}  // namespace mammon
#endif  //SAMI_CORE_AE_CYCLE_FIFO_BUFFER_H
