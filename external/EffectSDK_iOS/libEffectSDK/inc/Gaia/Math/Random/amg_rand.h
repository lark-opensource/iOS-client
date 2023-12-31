/**
 * @file amg_rand.h
 * @author fanjiaqi (fanjiaqi.837@bytedance.com)
 * @brief Random generator.
 * @version 0.1
 * @date 2019-12-04
 * 
 * @copyright Copyright (c) 2019
 * 
 */
#ifndef RAND_H
#define RAND_H

// Xorshift 128 implementation
// Xorshift paper: http://www.jstatsoft.org/v08/i14/paper
// Wikipedia: http://en.wikipedia.org/wiki/Xorshift
/**
 * @brief Random generator.
 * 
 */
class GAIA_LIB_EXPORT Rand
{
public:
    /**
     * @brief Construct a new Random generator.
     * 
     * @param seed Random number seed.
     */
    Rand(UInt32 seed = 0)
    {
        SetSeed(seed);
    }

    /**
     * @brief Generator next Random number.
     * 
     * @return UInt32 Random number generated.
     */
    UInt32 Get()
    {
        UInt32 t;
        t = x ^ (x << 11);
        x = y;
        y = z;
        z = w;
        return w = (w ^ (w >> 19)) ^ (t ^ (t >> 8));
    }

    /**
     * @brief Take 23 bits of integer, and divide by 2^23-1 to transfer to float between 0.0 and 1.0.
     * 
     * @param value Input integer.
     * @return float Transferred float between 0.0 and 1.0.
     */
    inline static float GetFloatFromInt(UInt32 value)
    {
        // take 23 bits of integer, and divide by 2^23-1
        return float(value & 0x007FFFFF) * (1.0f / 8388607.0f);
    }

    /**
     * @brief Take the most significant byte from the 23-bit value.
     * 
     * @param value Input integer.
     * @return UInt8 Significant byte of the value.
     */
    inline static UInt8 GetByteFromInt(UInt32 value)
    {
        // take the most significant byte from the 23-bit value
        return UInt8(value >> (23 - 8));
    }

    /**
     * @brief Generate a random number between 0.0 and 1.0.
     * 
     * @return float The random number generated.
     */
    float GetFloat()
    {
        return GetFloatFromInt(Get());
    }

    /**
     * @brief Generate a random number between -1.0 and 1.0.
     * 
     * @return float The random number generated.
     */
    float GetSignedFloat()
    {
        return GetFloat() * 2.0f - 1.0f;
    }

    /**
     * @brief Set the random number seed of current random generator.
     * 
     * @param seed The random number seed.
     */
    void SetSeed(UInt32 seed)
    {
        x = seed;
        y = x * 1812433253U + 1;
        z = y * 1812433253U + 1;
        w = z * 1812433253U + 1;
    }

    /**
     * @brief Get current random number seed.
     * 
     * @return UInt32 Current random number seed.
     */
    UInt32 GetSeed() const { return x; }

private:
    UInt32 x, y, z, w;
};

#endif
