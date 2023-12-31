/**
 * @file AMGHashFunction.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief Hash function
 * @version 10.20.0
 * @date 2019-12-18
 * @copyright Copyright (c) 2019
 */
#pragma once
#include <cmath>

#ifndef ISNAN
#ifdef WIN32
#include <math.h>
#define ISNAN(DATA) isnan(DATA)
#else
#define ISNAN(DATA) std::isnan(DATA)
#endif
#endif
/**
 * @brief DJB2
 */
class GAIA_LIB_EXPORT DJB2
{
    static inline uint32_t _hash(const uint64_t p_int)
    {
        uint64_t v = p_int;
        v = (~v) + (v << 18); // v = (v << 18) - v - 1;
        v = v ^ (v >> 31);
        v = v * 21; // v = (v + (v << 2)) + (v << 4);
        v = v ^ (v >> 11);
        v = v + (v << 6);
        v = v ^ (v >> 22);
        return (int)v;
    }

public:
    /// Hash int
    static constexpr uint32_t HASH_INT = 5381;

    /**
     * @brief Calculate hash of string
     * @param p_cstr string pointer
     * @param prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(const char* p_cstr, uint32_t prev = HASH_INT)
    {
        const uint8_t* chr = (const uint8_t*)p_cstr;
        uint32_t hash = prev;
        uint32_t c;

        while ((c = *chr++))
            hash = ((hash << 5) + hash) + c;

        return hash;
    }

    /**
     * @brief Calculate hash of buffer
     * @param buff buffer pointer
     * @param len buffer length
     * @param prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(const uint8_t* buff, int32_t len, uint32_t prev = HASH_INT)
    {

        uint32_t hash = prev;

        for (int i = 0; i < len; i++)
            hash = ((hash << 5) + hash) + buff[i];

        return hash;
    }

    /**
     * @brief Calculate hash of uint32_t
     * @param p_in uint32_t
     * @param p_prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(uint32_t p_in, uint32_t p_prev = HASH_INT)
    {

        return ((p_prev << 5) + p_prev) + p_in;
    }

    /**
     * @brief Calculate hash of int32_t
     * @param p_in int32_t
     * @param p_prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(int32_t p_in, uint32_t p_prev = HASH_INT)
    {

        return ((p_prev << 5) + p_prev) + p_in;
    }

    /**
     * @brief Calculate hash of int64_t
     * @param p_in int64_t
     * @param p_prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(int64_t p_in, uint32_t p_prev = HASH_INT)
    {

        return ((p_prev << 5) + p_prev) + _hash(p_in);
    }

    /**
     * @brief Calculate hash of double
     * @param p_in double
     * @param p_prev p_prev
     * @return uint32_t hash value
     */
    static inline uint32_t hash(double p_in, uint32_t p_prev = HASH_INT)
    {
        union
        {
            double d;
            uint64_t i;
        } u;

        if (p_in == 0.0f)
            u.d = 0.0;
        else if (ISNAN(p_in))
            u.d = NAN;
        else
            u.d = p_in;

        return ((p_prev << 5) + p_prev) + _hash(u.i);
    }
};
