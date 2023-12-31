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
 判断当前时间与传入的date是否是同一天

 @param date 待比较的时间
 @return 是同一天返回YES，否则返回NO
 */
- (BOOL)btd_isSameDay:(nonnull NSDate *)date;

- (BOOL)btd_isEarlierThanDate:(NSDate *)anotherDate;

- (BOOL)btd_isLaterThanDate:(NSDate *)anotherDate;

/**
 @return 返回当前时间所属的年月日时分秒
 */
- (NSInteger)btd_year;

- (NSInteger)btd_month;
- (NSInteger)btd_day;
- (NSInteger)btd_hour;
- (NSInteger)btd_minute;
- (NSInteger)btd_second;

/**
 @return 返回绝对时间
 */
+ (time_t)btd_uptime;
/**
 @return 返回一个新的时间对象，在当前时间的基础上累加年月日时分秒等
 */
- (nullable NSDate *)btd_dateByAddingYears:(NSInteger)years;
- (nullable NSDate *)btd_dateByAddingMonths:(NSInteger)months;
- (nullable NSDate *)btd_dateByAddingWeeks:(NSInteger)weeks;
- (nullable NSDate *)btd_dateByAddingDays:(NSInteger)days;
- (nullable NSDate *)btd_dateByAddingHours:(NSInteger)hours;
- (nullable NSDate *)btd_dateByAddingMinutes:(NSInteger)minutes;
- (nullable NSDate *)btd_dateByAddingSeconds:(NSInteger)seconds;
/**
 格式化当前时间

 @param format 例如 yyyy-MM-dd HH:mm:ss
 @return 返回一个经过格式化的时间字符串
 */
- (nullable NSString *)btd_stringWithFormat:(nonnull NSString *)format;
/**
 格式化当前时间

 @param format 例如 yyyy-MM-dd HH:mm:ss
 @param timeZone 时区
 @param locale 本地化信息
 @return 返回一个经过格式化的时间字符串
 */
- (nullable NSString *)btd_stringWithFormat:(nonnull NSString *)format timeZone:(nullable NSTimeZone *)timeZone locale:(nullable NSLocale *)locale;

/**
 根据字符串生成一个时间对象

 @param dateString 待解析的字符串
 @param format 字符串的格式 yyyy-MM-dd HH:mm:ss
 @return 返回一个字符串转换的时间对象
 */
+ (nullable NSDate *)btd_dateWithString:(nonnull NSString *)dateString format:(nonnull NSString *)format;

/**
 根据字符串生成一个时间对象

 @param dateString 待解析的字符串
 @param format 待解析的字符串
 @param timeZone 时区
 @param locale 本地化信息
 @return 返回一个字符串转换的时间对象
 */
+ (nullable NSDate *)btd_dateWithString:(nonnull NSString *)dateString format:(nonnull NSString *)format  timeZone:(nullable NSTimeZone *)timeZone locale:(nullable NSLocale *)locale;


/**
 返回当前date的ISO8610格式的字符串
 @return ISO8610格式的字符串 例如："2010-07-09T16:13:30+12:00"
 */
- (nullable NSString *)btd_ISO8601FormatedString;

/**
 用ISO8601格式的日期字符串初始化NSDate

 @param dateString ISO8601格式的日期字符串 例如："2010-07-09T16:13:30+12:00"
 @return NSDate
 */
+ (nullable NSDate *)btd_dateWithISO8601FormatedString:(NSString *)dateString;

@end

/**
 获取当前Mach绝对时间

 @return 当前Mach绝对时间
 */
FOUNDATION_EXPORT uint64_t BTDCurrentMachTime(void);

/**
 将Mach时间转换为秒

 @param time time
 @return 秒数
 */
FOUNDATION_EXPORT double BTDMachTimeToSecs(uint64_t time);

NS_ASSUME_NONNULL_END
