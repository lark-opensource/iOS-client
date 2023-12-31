//
//  NSDate+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/2/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (BTDAdditions)

/**
 Is the param date is the same with the current date?

 @param date A NSDate.
 @return The comparison result.
 */
- (BOOL)btd_isSameDay:(nonnull NSDate *)date;

- (BOOL)btd_isEarlierThanDate:(NSDate *)anotherDate;

- (BOOL)btd_isLaterThanDate:(NSDate *)anotherDate;

/**
 @return The year, month, day, hour, minute or second of now.
 */
- (NSInteger)btd_year;

- (NSInteger)btd_month;
- (NSInteger)btd_day;
- (NSInteger)btd_hour;
- (NSInteger)btd_minute;
- (NSInteger)btd_second;

/**
 @return the weekday number between 1 and N (where for the Gregorian calendar N=7 and 1 is Sunday).
 */
- (NSInteger)btd_weekday;

/**
 @return Return an absolute time.
 */
+ (time_t)btd_uptime;
/**
 @return Return a NSDate after years, months, weeks, days, hours, minutes or seconds from now.
 */
- (nullable NSDate *)btd_dateByAddingYears:(NSInteger)years;
- (nullable NSDate *)btd_dateByAddingMonths:(NSInteger)months;
- (nullable NSDate *)btd_dateByAddingWeeks:(NSInteger)weeks;
- (nullable NSDate *)btd_dateByAddingDays:(NSInteger)days;
- (nullable NSDate *)btd_dateByAddingHours:(NSInteger)hours;
- (nullable NSDate *)btd_dateByAddingMinutes:(NSInteger)minutes;
- (nullable NSDate *)btd_dateByAddingSeconds:(NSInteger)seconds;
/**
 Return a format string of the current time.

 @param format For example, yyyy-MM-dd HH:mm:ss.
 @return A format string.
 */
- (nullable NSString *)btd_stringWithFormat:(nonnull NSString *)format;
/**
 Return a format string of the current time.

 @param format For example, yyyy-MM-dd HH:mm:ss.
 @param timeZone The time zone.
 @param locale Localization information.
 @return A format string.
 */
- (nullable NSString *)btd_stringWithFormat:(nonnull NSString *)format timeZone:(nullable NSTimeZone *)timeZone locale:(nullable NSLocale *)locale;

/**
 Convert a date string to a NSDate.

 @param dateString A date string.
 @param format For example, yyyy-MM-dd HH:mm:ss.
 @return A NSDate.
 */
+ (nullable NSDate *)btd_dateWithString:(nonnull NSString *)dateString format:(nonnull NSString *)format;

/**
 Convert a date string to a NSDate.

 @param dateString A date string.
 @param format For example, yyyy-MM-dd HH:mm:ss.
 @param timeZone The time zone.
 @param locale Localization information.
 @return A NSDate.
 */
+ (nullable NSDate *)btd_dateWithString:(nonnull NSString *)dateString format:(nonnull NSString *)format  timeZone:(nullable NSTimeZone *)timeZone locale:(nullable NSLocale *)locale;

/**
 @return a NSDate initiated with the year, month, day, hour, minute, second.
 */
+ (nullable NSDate *)btd_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second;

/**
 @return The number of days in the month of the year.
 */
+ (NSUInteger)btd_daysInMonth:(NSInteger)month year:(NSInteger)year;

/**
 Convert the current NSDate to an ISO8610 string.
 @return An ISO8610 string. For example, "2010-07-09T16:13:30+12:00".
 */
- (nullable NSString *)btd_ISO8601FormatedString;

/**
 Convert  an ISO8610 string to a NSDate.

 @param dateString An ISO8610 string. For example, "2010-07-09T16:13:30+12:00".
 @return A NSDate.
 */
+ (nullable NSDate *)btd_dateWithISO8601FormatedString:(NSString *)dateString;

@end

/**
 Return the current mach time.

 @return The current mach time.
 */
FOUNDATION_EXPORT uint64_t BTDCurrentMachTime(void);

/**
 Convert a mach time to seconds.

 @param time A mach time.
 @return Seconds.
 */
FOUNDATION_EXPORT double BTDMachTimeToSecs(uint64_t time);

NS_ASSUME_NONNULL_END
