/**
 * @file AMGSystemTime.h
 * @author wangze (wangze.happy@bytedance.com)
 * @brief System time
 * @version 10.21.0
 * @date 2019-12-19
 * @copyright Copyright (c) 2019
 */
#ifndef SYSTEMTIME_H
#define SYSTEMTIME_H

#include "Gaia/AMGPrerequisites.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief Date time class
 */
class GAIA_LIB_EXPORT FDateTime
{
public:
    /// 秒 - 取值区间为[0,59]
    int32_t m_second = 0;
    /// 分 - 取值区间为[0,59]
    int32_t m_minute = 0;
    /// 时 - 取值区间为[0,23]
    int32_t m_hour = 0;
    /// 一个月中的日期 - 取值区间为[1,31]
    int32_t m_monthday = 0;
    /// 月份 - 取值区间为[1,12]
    int32_t m_month = 0;
    /// 年份 - 其值等于实际年份
    int32_t m_year = 0;
    /// 星期几 - 取值区间为[1,7]
    int32_t m_weekday = 0;

    /// Constructor
    FDateTime(){};

    /**
     * @brief Constructor
     * @param second second
     * @param minute minute
     * @param hour hour
     * @param monthday day
     * @param month month
     * @param year year
     * @param weekday week day
     */
    FDateTime(int32_t second, int32_t minute, int32_t hour, int32_t monthday, int32_t month, int32_t year, int32_t weekday)
        : m_second(second)
        , m_minute(minute)
        , m_hour(hour)
        , m_monthday(monthday)
        , m_month(month)
        , m_year(year)
        , m_weekday(weekday)
    {
    }
};

/**
 * @brief Generic implementation for System time
 */
class GAIA_LIB_EXPORT FSystemTime
{
public:
    /// Get seconds
    static double seconds();
    /// Get date time
    static FDateTime getDateTime();

    /// Get system time by millisecond
    static int64_t getSystemTimeMS();
    /// Get system time by microsecond
    static int64_t getSystemTimeUS();
};

/**
 * @brief Timer base class
 */
class GAIA_LIB_EXPORT FTimerBase
{
public:
    /// Constructor
    FTimerBase();
    /// Reset timer
    void reset();
    /// Get elapsed time by seconds
    double elapsedSeconds() const;
    /// Get elapsed time by milliseconds
    int64_t elapsedMilliseconds() const;
    /// Get elapsed time by microseconds
    int64_t elapsedMicroseconds() const;

private:
    double m_begin = 0.0;
};

NAMESPACE_AMAZING_ENGINE_END

#endif //SYSTEMTIME_H
