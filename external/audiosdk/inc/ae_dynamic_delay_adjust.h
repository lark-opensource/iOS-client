//
// Created by yangchuang.allen on 2022/11/24.
//

#ifndef SAMI_CORE_AE_DYNAMIC_DELAY_ADJUST_H
#define SAMI_CORE_AE_DYNAMIC_DELAY_ADJUST_H
#include "ae_cycle_fifo_buffer.h"

namespace mammon {

template <typename T>
class MAMMON_EXPORT DynamicDelayAdjustX {
public:
    DynamicDelayAdjustX()=default;
    virtual ~DynamicDelayAdjustX()=default;
    //init delay status
    void init(int delay_samples){
        delay_cnt_ = delay_samples;
        buffer_.clear();
        if (delay_cnt_ > 0) {
            buffer_.resize(delay_cnt_);
            T *ptr = buffer_.ptrBegin();
            memset(ptr, 0, delay_cnt_ * sizeof(T));
            buffer_.fakeWrite(delay_cnt_);
        }
        if (delay_cnt_ <= 0) {
            neg_cnt_ = delay_cnt_;
            neg_init = false;
        }
    }
    //adjust delay in runtime,will dynamic cal real need delay samples
    void adjustDelay(int delay_samples){
        if (delay_cnt_ <= 0) {
            int dropedCnt = 0;

            if (neg_cnt_ > 0) {
                dropedCnt = 0 - delay_cnt_;
            } else {
                dropedCnt = (0 - delay_cnt_) + neg_cnt_;
            }
            int realDelayCnt = delay_samples + dropedCnt;
            if (realDelayCnt > 0) {
                CycleFifoBufferX<T> tmpBuffer(realDelayCnt + buffer_.getAvailableSize());
                tmpBuffer.fakeWrite(realDelayCnt);
                tmpBuffer.moveData(buffer_);
                buffer_.moveData(tmpBuffer);
                neg_cnt_ = 0;
                neg_init = true;
            } else {
                neg_cnt_ = realDelayCnt;
                neg_init = false;
            }
        } else {
            int diff = delay_samples - delay_cnt_;
            if (diff > 0) {
                CycleFifoBufferX<T> tmpBuffer(diff + buffer_.getAvailableSize());
                tmpBuffer.fakeWrite(diff);
                tmpBuffer.moveData(buffer_);
                buffer_.moveData(tmpBuffer);
                neg_cnt_ = 0;
                neg_init = true;
            } else {
                neg_init = false;
                neg_cnt_ = diff;
            }
        }

        delay_cnt_ = delay_samples;
    }
    size_t process(T* data,size_t samples_cnt){
        if(delay_cnt_<=0 && neg_cnt_==0 && neg_init==true){
            return samples_cnt;//drop has finished,no need to move copy data
        }
        return process((const T*)data,data,samples_cnt);
    }

    size_t process(const T* in, T* out,size_t samples_cnt){
        if(delay_cnt_<=0 && neg_cnt_==0 && neg_init==true){
            memcpy(out,in,samples_cnt*sizeof(T));//drop has finished,no need to move copy data
            return samples_cnt;
        }

        buffer_.write(in, samples_cnt);
        memset(out,0,sizeof(float)*samples_cnt);
        int buflen = buffer_.getAvailableSize();

        if (delay_cnt_<0 && neg_init== false) {
            if (neg_cnt_ + buflen >= 0) {
                buffer_.fakeRead(0 - neg_cnt_);
                neg_init = true;
                neg_cnt_ = 0;
                return buffer_.read(out, samples_cnt);
            } else {
                neg_cnt_ += buflen;
                buffer_.clear();
                return 0;
            }
        } else {
            return buffer_.read(out, samples_cnt);
        }
    }
    bool dropFinished(){
        return neg_cnt_==0 && neg_init==true;
    }
private:
    int delay_cnt_=0;
    int neg_cnt_=0;
    int neg_init=false;
    CycleFifoBufferX<T> buffer_;
};
}  // namespace mammon
#endif  //SAMI_CORE_AE_DYNAMIC_DELAY_ADJUST_H
