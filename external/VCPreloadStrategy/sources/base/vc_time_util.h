//
// Created by zhongzhendong on 12/1/20.
//

#ifndef PRELOAD_VC_TIME_UTIL_H
#define PRELOAD_VC_TIME_UTIL_H

#include "vc_base.h"
#include <chrono>

VC_NAMESPACE_BEGIN

typedef uint32_t TimeStamp;

static const int64_t kNumNanosPerSec = INT64_C(1000000000);
static const int64_t kNumMicrosPerSec = INT64_C(1000000);
static const int64_t kNumMillisPerSec = INT64_C(1000);

static const int64_t kNumNanosecsPerMicrosec =
        kNumNanosPerSec / kNumMicrosPerSec;
static const int64_t kNumNanosecsPerMillisec =
        kNumNanosPerSec / kNumMillisPerSec;
static const int64_t kNumMicrosecsPerMillisec =
        kNumMicrosPerSec / kNumMillisPerSec;
uint64_t VCNowTimeMillis();
uint64_t VCNowTimeMicros();
uint64_t VCNowTimeNanos();

uint64_t VCTimeAfter(int32_t elapsed);
bool VCTimeIsLater(uint32_t earlier, uint32_t later);
bool VCTimeIsLaterOrEqual(uint32_t earlier, uint32_t later);
uint64_t VCTimeDiff(uint64_t later, uint64_t earlier);

inline uint64_t VCTimeSince(uint64_t earlier) {
    return VCTimeDiff(VCNowTimeMillis(), earlier);
}

inline uint64_t VCTimeUntil(uint64_t later) {
    return VCTimeDiff(later, VCNowTimeMillis());
}

inline uint32_t VCTimeMax(uint32_t ts1, uint32_t ts2) {
    return VCTimeIsLaterOrEqual(ts1, ts2) ? ts2 : ts1;
}

inline uint32_t VCTimeMin(uint32_t ts1, uint32_t ts2) {
    return VCTimeIsLaterOrEqual(ts1, ts2) ? ts1 : ts2;
}

class HourMinute : public IVCPrintable {
public:
    typedef std::shared_ptr<HourMinute> Ptr;

public:
    HourMinute() = default;
    ~HourMinute() override = default;

public:
    std::string toString() const override {
        return string_format("%02d:%02d", mHour, mMinute);
    }

    bool parse(std::string str) {
        size_t index = str.find(':');
        if (index == std::string::npos) {
            return false;
        }
        mHour = std::strtol(str.c_str(), nullptr, 10);
        mMinute = std::strtol(str.c_str() + index + 1, nullptr, 10);
        return true;
    }

public:
    inline bool operator<(const HourMinute &o) const {
        return (mHour == o.mHour && mMinute < o.mMinute) || (mHour < o.mHour);
    }

    inline bool operator>(const HourMinute &o) const {
        return (mHour == o.mHour && mMinute > o.mMinute) || (mHour > o.mHour);
    }

    inline bool operator<=(const HourMinute &o) const {
        return !(*this > o);
    }

    inline bool operator>=(const HourMinute &o) const {
        return !(*this < o);
    }

    inline bool operator!=(const HourMinute &o) const {
        return (mHour != o.mHour) || (mMinute != o.mMinute);
    }

    inline bool operator==(const HourMinute &o) const {
        return (mHour == o.mHour) && (mMinute == o.mMinute);
    }

public:
    int mHour{0};
    int mMinute{0};
};

class VCTimeDuration {
public:
    constexpr VCTimeDuration() = default;

    static constexpr VCTimeDuration FromNanoseconds(int64_t nanosecond) {
        return VCTimeDuration(nanosecond);
    }

    static constexpr VCTimeDuration FromMilliseconds(int64_t millis) {
        return FromMicroseconds(millis * 1000);
    }

    static constexpr VCTimeDuration FromMicroseconds(int64_t micros) {
        return FromNanoseconds(micros * 1000);
    }

    static constexpr VCTimeDuration FromSeconds(int64_t seconds) {
        return FromMilliseconds(seconds * 1000);
    }

    static constexpr VCTimeDuration FromSecondsFloat(double seconds) {
        return FromNanoseconds(seconds * (1000.0 * 1000.0 * 1000.0));
    }

    constexpr int64_t ToNanosecs() const {
        return mDelta;
    }

    constexpr int64_t ToMicrosecs() const {
        return ToNanosecs() / 1000;
    }

    constexpr int64_t ToMillisecs() const {
        return ToMicrosecs() / 1000;
    }

    constexpr int64_t ToSeconds() const {
        return ToMillisecs() / 1000;
    }

    constexpr double ToNanosecondsFloat() const {
        return mDelta;
    }

    constexpr double ToMicrosecondsFloat() const {
        return mDelta / 1000.0;
    }

    constexpr double ToMillisecondsFloat() const {
        return mDelta / (1000.0 * 1000.0);
    }

    constexpr double ToSecondsFloat() const {
        return mDelta / (1000.0 * 1000.0 * 1000.0);
    }

    constexpr VCTimeDuration operator/(int64_t divisor) const {
        return VCTimeDuration(mDelta / divisor);
    }

    constexpr VCTimeDuration operator-(VCTimeDuration o) const {
        return VCTimeDuration(mDelta - o.mDelta);
    }

    constexpr int64_t operator/(VCTimeDuration other) const {
        return mDelta / other.mDelta;
    }

    constexpr VCTimeDuration operator%(VCTimeDuration o) const {
        return VCTimeDuration(mDelta % o.mDelta);
    }

    constexpr VCTimeDuration operator+(VCTimeDuration o) const {
        return VCTimeDuration(mDelta + o.mDelta);
    }

    constexpr VCTimeDuration operator*(int64_t multiplier) const {
        return VCTimeDuration(mDelta * multiplier);
    }

    bool operator==(VCTimeDuration o) const {
        return mDelta == o.mDelta;
    }

    bool operator!=(VCTimeDuration o) const {
        return mDelta != o.mDelta;
    }

    bool operator>(VCTimeDuration o) const {
        return mDelta > o.mDelta;
    }

    bool operator<(VCTimeDuration o) const {
        return mDelta < o.mDelta;
    }

    bool operator>=(VCTimeDuration o) const {
        return mDelta >= o.mDelta;
    }

    bool operator<=(VCTimeDuration o) const {
        return mDelta <= o.mDelta;
    }

    static constexpr VCTimeDuration FromTimespec(struct timespec ts) {
        return VCTimeDuration(ts.tv_sec) + VCTimeDuration(ts.tv_nsec);
    }

    static constexpr VCTimeDuration Zero() {
        return {};
    }

    static constexpr VCTimeDuration Max() {
        return VCTimeDuration(std::numeric_limits<int64_t>::max());
    }

    static constexpr VCTimeDuration Min() {
        return VCTimeDuration(std::numeric_limits<int64_t>::min());
    }

    struct timespec ToTimespec() {
        struct timespec ts;
        constexpr int64_t kNanosecondsPerSecond = 1000000000ll;
        ts.tv_sec = static_cast<time_t>(ToSeconds());
        ts.tv_nsec = mDelta % kNanosecondsPerSecond;
        return ts;
    }

private:
    // Private, use one of the FromFoo() types
    explicit constexpr VCTimeDuration(int64_t delta) : mDelta(delta) {}

    int64_t mDelta = 0;
};

class VCTimePoint {
public:
    constexpr VCTimePoint() = default;

    static constexpr VCTimePoint FromEpochDelta(VCTimeDuration ticks) {
        return VCTimePoint(ticks.ToNanosecs());
    }

    VCTimeDuration ToEpochDelta() const {
        return VCTimeDuration::FromNanoseconds(mTicks);
    }

    // Compute the difference between two time points.
    VCTimeDuration operator-(VCTimePoint other) const {
        return VCTimeDuration::FromNanoseconds(mTicks - other.mTicks);
    }

    VCTimePoint operator+(VCTimeDuration duration) const {
        return VCTimePoint(mTicks + duration.ToNanosecs());
    }

    VCTimePoint operator-(VCTimeDuration duration) const {
        return VCTimePoint(mTicks - duration.ToNanosecs());
    }

    bool operator!=(VCTimePoint o) const {
        return mTicks != o.mTicks;
    }

    bool operator==(VCTimePoint o) const {
        return mTicks == o.mTicks;
    }

    bool operator<=(VCTimePoint o) const {
        return mTicks <= o.mTicks;
    }

    bool operator<(VCTimePoint o) const {
        return mTicks < o.mTicks;
    }

    bool operator>=(VCTimePoint o) const {
        return mTicks >= o.mTicks;
    }

    bool operator>(VCTimePoint o) const {
        return mTicks > o.mTicks;
    }

    static VCTimePoint Now();

    static constexpr VCTimePoint Min() {
        return VCTimePoint(std::numeric_limits<int64_t>::min());
    }

    static constexpr VCTimePoint Max() {
        return VCTimePoint(std::numeric_limits<int64_t>::max());
    }

private:
    explicit constexpr VCTimePoint(int64_t ticks) : mTicks(ticks) {}

    int64_t mTicks = 0;
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_TIME_UTIL_H
