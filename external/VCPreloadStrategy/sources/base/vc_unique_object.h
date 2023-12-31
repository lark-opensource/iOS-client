//
// Created by zhongzhendong on 2020/12/2.
//

#ifndef STRATEGYCENTER_UNIQUE_OBJECT_H
#define STRATEGYCENTER_UNIQUE_OBJECT_H

#include "vc_base.h"

VC_NAMESPACE_BEGIN

template <typename T, typename Traits>
class VCUniqueObject {
private:
    // This must be first since it's used inline below.
    //
    // Use the empty base class optimization to allow us to have a Traits
    // member, while avoiding any space overhead for it when Traits is an
    // empty class.  See e.g. http://www.cantrip.org/emptyopt.html for a good
    // discussion of this technique.
    struct Data : public Traits {
        explicit Data(const T &in) : value(in) {}

        Data(const T &in, const Traits &other) : Traits(other), value(in) {}

        T value;
    };

public:
    using traits_type = Traits;
    using element_type = T;

    explicit VCUniqueObject(const T &value) : mData(value) {}

    VCUniqueObject() : mData(Traits::InvalidValue()) {}

    VCUniqueObject(const T &value, const Traits &traits) :
            mData(value, traits) {}

    VCUniqueObject(VCUniqueObject &&other) :
            mData(other.release(), other.get_traits()) {}

    ~VCUniqueObject() {
        FreeIfNecessary();
    }

    VCUniqueObject &operator=(VCUniqueObject &&other) {
        reset(other.release());
        return *this;
    }

    void swap(VCUniqueObject &other) {
        using std::swap;
        swap(static_cast<Traits &>(mData), static_cast<Traits &>(other.mData));
        swap(mData.value, other.mData.value);
    }

    void reset(const T &value = Traits::InvalidValue()) {
        assert(mData.value == Traits::InvalidValue() || mData.value != value);
        FreeIfNecessary();
        mData.value = value;
    }

    [[nodiscard]] T release() {
        T old_value = mData.value;
        mData.value = Traits::InvalidValue();
        return old_value;
    }

    const T &get() const {
        return mData.value;
    }

    bool is_valid() const {
        return Traits::IsValid(mData.value);
    }

    bool operator!=(const T &value) const {
        return mData.value != value;
    }

    bool operator==(const T &value) const {
        return mData.value == value;
    }

    Traits &get_traits() {
        return mData;
    }

    const Traits &get_traits() const {
        return mData;
    }

private:
    void FreeIfNecessary() {
        if (mData.value != Traits::InvalidValue()) {
            mData.Free(mData.value);
            mData.value = Traits::InvalidValue();
        }
    }

    template <typename T2, typename Traits2>
    bool operator!=(const VCUniqueObject<T2, Traits2> &p2) const = delete;

    template <typename T2, typename Traits2>
    bool operator==(const VCUniqueObject<T2, Traits2> &p2) const = delete;

    Data mData;

    VC_DISALLOW_COPY_AND_ASSIGN(VCUniqueObject);
};

template <class T, class Traits>
void swap(const VCUniqueObject<T, Traits> &a,
          const VCUniqueObject<T, Traits> &b) {
    a.swap(b);
}

template <class T, class Traits>
bool operator!=(const T &value, const VCUniqueObject<T, Traits> &object) {
    return !(value == object.get());
}

template <class T, class Traits>
bool operator==(const T &value, const VCUniqueObject<T, Traits> &object) {
    return value == object.get();
}

VC_NAMESPACE_END

#endif // STRATEGYCENTER_UNIQUE_OBJECT_H
