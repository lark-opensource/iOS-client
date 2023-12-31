//
// Created by william on 2019-05-08.
//

#pragma once
#include <stdint.h>
#include <cmath>
#include "ae_defs.h"

namespace mammon {

template <typename T>
class normalDistribution {
public:
    explicit normalDistribution(T mean = 0, T std = 1): mean_(mean), std_(std) {
    }

    T mean() const {
        return mean_;
    }
    T std() const {
        return std_;
    }

private:
    T mean_;
    T std_;
};

typedef normalDistribution<double> normal;

class MAMMON_EXPORT MathUtils {
public:
    static constexpr double PI = 3.141592653;

    static bool isPowerOf2(uint32_t n) {
        return (n & (n - 1)) == 0;
    }

    static uint32_t getNextNearsetPowerTwo4uint32_t(uint32_t notpow2size){
        notpow2size--;
        notpow2size |= notpow2size >> 1;
        notpow2size |= notpow2size >> 2;
        notpow2size |= notpow2size >> 4;
        notpow2size |= notpow2size >> 8;
        notpow2size |= notpow2size >> 16;
        notpow2size++;
        return notpow2size;
    }

    static int16_t float2int16(float x);

    static float rescale(float x, float max_val);

    static double normalPDF(const normal& dist, double x);
};

// Returns the factorial (!) of x. If x < 0, it returns 0.
inline float factorial(int x) {
    if(x < 0) return 0.0f;
    float result = 1.0f;
    for(; x > 0; --x) result *= static_cast<float>(x);
    return result;
}
// Returns the double factorial (!!) of x.
// For odd x:  1 * 3 * 5 * ... * (x - 2) * x
// For even x: 2 * 4 * 6 * ... * (x - 2) * x
// If x < 0, it returns 0.
inline float doubleFactorial(int x) {
    if(x < 0) return 0.0f;
    float result = 1.0f;
    for(; x > 0; x -= 2) result *= static_cast<float>(x);
    return result;
}

inline float linearToDecibels(float linear_val) {
    return 20 * log10(linear_val + 1e-8);
}
}  // namespace mammon
