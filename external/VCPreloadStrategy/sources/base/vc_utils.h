// Created by 黄清 on 2020/5/22.
//

#ifndef Utils_hpp
#define Utils_hpp
#pragma once

#include "vc_base.h"
#include "vc_json.h"
#include <algorithm>
#include <cassert>
#include <cmath>
#include <limits>
#include <string>
#include <utility>

VC_NAMESPACE_BEGIN

class VCMethodConsume {
public:
    explicit VCMethodConsume(const std::string &des);
    ~VCMethodConsume();

private:
    static uint64_t Serial_num;

private:
    std::string mDes;
    uint64_t mMSTime{0};
    uint64_t mSerialNum{0};

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCMethodConsume);
};

#ifndef __METHOD_CONSUME__
#define __METHOD_CONSUME__

#define DEBUG_TIMING 0
#if DEBUG || DEBUG_TIMING
#define METHOD_CONSUME(des) \
    __attribute__((__unused__)) VCMethodConsume unUseInstace(des)
#else
#define METHOD_CONSUME(des)
#endif
#endif

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

namespace Utils {

std::vector<std::string> split(const std::string &str,
                               const std::string &delim);

bool contains(VCStrCRef s, VCStrCRef infix);

bool startsWith(VCStrCRef s, VCStrCRef prefix);

bool endsWith(VCStrCRef s, VCStrCRef suffix);

bool invalidJsonString(VCStrCRef json);

/*
std::int64_t getCurrentTimestamp(void);
*/
std::string mapToString(const StringValueMap &map);
StringValueMap stringToMap(const std::string &str);
std::string longValueMapToString(const LongValueMap &map);
/*
LongValueMap stringToLongValueMap(const std::string &str);
*/

#if defined(__ANDROID__)
bool attachEnv(void);
void detachEnv(void);
#endif

std::string BuildPlayerID(const std::string &sceneId,
                          const std::string &mediaId);

/**
 * Probability mass function of discrete uniform distribution U{a, b}
 * @note The relative order of (a, b) is autocorrected
 * @param a left boundary (inclusive)
 * @param b right boundary (inclusive)
 * @param k parameter
 * @return probability P(X = k) for X ~ U{a, b}
 */
template <typename IntType,
          typename = std::enable_if_t<std::is_integral_v<IntType> &&
                                      !std::is_same_v<IntType, bool>>>
constexpr inline double
DiscreteUniformDistPMF(IntType a, IntType b, IntType k) {
    auto minmax = std::minmax(a, b);
    if (k < minmax.first || k > minmax.second)
        return 0;
    return 1.0 / (minmax.second - minmax.first + 1);
}

/**
 * Cumulative distribution function of discrete uniform distribution U{a, b}
 * @note The relative order of (a, b) is autocorrected
 * @param a left boundary (inclusive)
 * @param b right boundary (inclusive)
 * @param k parameter
 * @return probability P(X \<= k) for X ~ U{a, b}
 */
template <typename IntType,
          typename = std::enable_if_t<std::is_integral_v<IntType> &&
                                      !std::is_same_v<IntType, bool>>>
constexpr inline double
DiscreteUniformDistCDF(IntType a, IntType b, IntType k) {
    auto minmax = std::minmax(a, b);
    if (k < minmax.first)
        return 0;
    if (k > minmax.second)
        return 1;
    return (double)(k - minmax.first + 1) /
           (double)(minmax.second - minmax.first + 1);
}

/**
 * Cumulative distribution function of continuous uniform distribution U[a, b]
 * @note The relative order of (a, b) is autocorrected
 * @param a left boundary (inclusive)
 * @param b right boundary (inclusive)
 * @param x parameter
 * @return probability P(X \<= x) for X ~ U[a, b]
 */
constexpr inline double ContinuousUniformDistCDF(double a, double b, double x) {
    auto minmax = std::minmax(a, b);
    if (x < minmax.first)
        return 0;
    if (x > minmax.second)
        return 1;
    return (x - minmax.first) / (minmax.second - minmax.first);
}

/**
 * Probability mass function of continuous uniform distribution U[a, b]
 * @note The relative order of (a, b) and (x, y) is autocorrected
 * @param a left boundary (inclusive)
 * @param b right boundary (inclusive)
 * @param x parameter
 * @param y parameter
 * @return probability P(x \< X \<= y) for X ~ U[a, b]
 */
constexpr inline double
ContinuousUniformDistPMF(double a, double b, double x, double y) {
    auto minmax = std::minmax(x, y);
    return ContinuousUniformDistCDF(a, b, minmax.second) -
           ContinuousUniformDistCDF(a, b, minmax.first);
}

/**
 * Cumulative distribution function of normal distribution N(mu, sigma^2)
 * @param mu mean
 * @param sigma standard deviation
 * @param x parameter
 * @return probability P(X \<= x) for X ~ N(mu, sigma^2)
 */
double NormalDistCDF(double mu, double sigma, double x);

/**
 * Probability mass function of normal distribution N(mu, sigma^2)
 * @note The relative order of (x, y) is autocorrected
 * @param mu mean
 * @param sigma standard deviation
 * @param x parameter
 * @param y parameter
 * @return probability P(x \< X \<= y) for X ~ N(mu, sigma^2)
 */
double NormalDistPMF(double mu, double sigma, double x, double y);

/**
 * Probability mass function of Poisson distribution Pois(lambda)
 * @param lambda parameter, required to be positive
 * @param k parameter
 * @return possibility P(X = k) for X ~ Pois(lambda)
 */
template <typename UnsignedType,
          typename = std::enable_if_t<std::is_unsigned_v<UnsignedType> &&
                                      !std::is_same_v<UnsignedType, bool>>>
constexpr inline double PoissonDistPMF(double lambda, UnsignedType k) {
    assert(lambda > 0);
    double result = 1;
    for (; k > 0; --k) {
        result *= lambda / k;
    }
    result *= std::exp(-lambda);
    return result;
}

/**
 * Cumulative distribution function of Poisson distribution Pois(lambda)
 * @param lambda mean and variance, required to be positive
 * @param k parameter
 * @return possibility P(X \<= k) for X ~ Pois(lambda)
 */
template <typename UnsignedType,
          typename = std::enable_if_t<std::is_unsigned_v<UnsignedType> &&
                                      !std::is_same_v<UnsignedType, bool>>>
constexpr inline double PoissonDistCDF(double lambda, UnsignedType k) {
    assert(lambda > 0);
    double result = 0;
    for (UnsignedType i = 0; i <= k; ++i) {
        double prod = 1;
        for (UnsignedType j = i; j > 0; --j) {
            prod *= lambda / j;
        }
        result += prod;
    }
    result *= std::exp(-lambda);
    return result;
}

class StatisticsHelper {
public:
    void putItem(double value) {
        count++;
        currentSum += value;
        currentSumSquares += value * value;
    }

    double getAvg(void) const {
        if (count == 0) {
            return std::numeric_limits<double>::quiet_NaN();
        }
        return currentSum / count;
    }

    double getStdDev(void) const {
        if (count <= 1) {
            return std::numeric_limits<double>::quiet_NaN();
        }
        return sqrt((currentSumSquares / (count - 1)) -
                    pow((currentSum / count), 2) * count / (count - 1));
    }

    void clear(void) {
        count = 0;
        currentSum = 0;
        currentSumSquares = 0;
    }

private:
    int count{0};

    double currentSum{0};
    double currentSumSquares{0};
};

} // namespace Utils

/// 区间分桶统计
template <typename T>
struct BucketLog {
    T min, max, sum;
    unsigned cnt;
    /// 区间分桶
    std::vector<std::pair<T, unsigned>> buckets;

    BucketLog(const std::vector<T> &bkt) :
            min{std::numeric_limits<T>::max()},
            max{std::numeric_limits<T>::min()},
            sum{},
            cnt{} {
        buckets.reserve(bkt.size());
        for (T i : bkt) {
            buckets.emplace_back(i, 0u);
        }
    }

    void put(T value) {
        auto bucketIt = std::find_if(buckets.rbegin(),
                                     buckets.rend(),
                                     [&](const std::pair<T, size_t> &pair) {
                                         return pair.first <= value;
                                     });
        if (bucketIt != buckets.rend()) {
            bucketIt->second++;
            max = std::max(max, value);
            min = std::min(min, value);
            sum += value;
            cnt++;
        }
    }

    VCJson toJson() const {
        if (cnt == 0)
            return {};

        T avg = sum / cnt;
        VCJson json(VCJson::ValueType::Object);
        json["max"] = max;
        json["min"] = min;
        json["avg"] = avg;
        json["buckets"] = VCJson(VCJson::ValueType::Object);
        for (auto &&pair : buckets) {
            json["buckets"][std::to_string(pair.first)] = pair.second;
        }

        return json;
    }
};

VC_NAMESPACE_END

#endif /* Utils_hpp */
