//
// Created by liushilei on 2022/10/25.
//

#ifndef LIMITER_SMOOTHERDATA_H
#define LIMITER_SMOOTHERDATA_H
namespace mammon {
template <typename T>
class SmootherData {
public:
    virtual T process(T x) {
        data_ = attack_param_ * data_ + (1 - attack_param_) * x;
        return data_;
    }
    virtual T processInv(T x) {
        return process(x);
    }
    virtual ~SmootherData() = default;
    virtual T set(T x) {
        data_ = x;
        return data_;
    }

    virtual void setParam(T smooth_param) {
        attack_param_ = smooth_param;
    }

protected:
    T data_ = T(0);
    T attack_param_ = T(0);
};

template <typename T>
class SmootherAttackReleaseData : public SmootherData<T> {
public:
    T process(T x) override {
#ifdef EXTREME_SIMPLIFY
        if (x <= SmootherData<T>::data_) {
            SmootherData<T>::data_ = release_param_ * SmootherData<T>::data_ + (1 - release_param_) * x;
        } else {
            SmootherData<T>::data_ = x;
        }
        return SmootherData<T>::data_;
#else
        auto para_temp = x > SmootherData<T>::data_ ? SmootherData<T>::attack_param_ : release_param_;
        SmootherData<T>::data_ = para_temp * SmootherData<T>::data_ + (1 - para_temp) * x;
        return SmootherData<T>::data_;
#endif
    }
    T processInv(T x) override {
#ifdef EXTREME_SIMPLIFY
        // if (x >= SmootherData<T>::data_) {
        //     SmootherData<T>::data_ = release_param_ * SmootherData<T>::data_ + (1 - release_param_) * x;
        // } else {
        //     SmootherData<T>::data_ = x;
        // }
        SmootherData<T>::data_ = x >= SmootherData<T>::data_ ? release_param_ * (SmootherData<T>::data_ - x) + x : x;
        return SmootherData<T>::data_;
#else
        auto para_temp = x <= SmootherData<T>::data_ ? SmootherData<T>::attack_param_ : release_param_;
        SmootherData<T>::data_ = para_temp * SmootherData<T>::data_ + (1 - para_temp) * x;
        return SmootherData<T>::data_;
#endif
    }
    void setParam(T attack_param, T release_param) {
        release_param_ = release_param;
        SmootherData<T>::attack_param_ = attack_param;
    }

    void setParam(T attack_param) override {
        setParam(attack_param, T(10) * attack_param);
    }

private:
    T release_param_ = T(0);
};
}// namespace mammon
#endif  // LIMITER_SMOOTHERDATA_H
