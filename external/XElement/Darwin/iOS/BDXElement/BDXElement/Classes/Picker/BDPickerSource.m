//
//  BDPickerSource.m
//  AWEAppConfigurations
//
//  Created by annidy on 2020/5/8.
//

#import "BDPickerSource.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDXElementResourceManager.h"

static const NSInteger kStartYear = 1900;
static const NSInteger kEndYear = 2100;
static const NSInteger kStartMonth = 2;
static const NSInteger kEndMonth = 13;

NSString *const kBDXPickerSourceModeSelector = @"selector";
NSString *const kBDXPickerSourceModeMultiSelector = @"multiSelector";
NSString *const kBDXPickerSourceModeTime = @"time";
NSString *const kBDXPickerSourceModeDate = @"date";
// TODO(wujintian): Delete legacy code.
NSString *const kBDXPickerSourceModeSelectorLegacy = @"selectorLegacy";
NSString *const kBDXPickerSourceModeMultiSelectorLegacy = @"multiSelectorLegacy";
NSString *const kBDXPickerSourceModeTimeLegacy = @"timeLegacy";
NSString *const kBDXPickerSourceModeDateLegacy = @"dateLegacy";



@implementation BDXPickerSource

- (NSInteger)numberOfComponents {
    return 0;
}
- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    return 0;
}
- (NSString *)stringValueForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"";
}

- (NSDate *)startDate {
    return nil;
}
- (NSDate *)endDate {
    return nil;
}
- (NSDate *)valueDate {
    return nil;
}

- (NSArray<NSNumber *> *)valuesRow {
    return @[];
}

@end

@implementation BDXPickerSelectorSource

- (NSInteger)numberOfComponents {
    return 1;
}
- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    return self.range.count;
}
- (NSString *)stringValueForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row >= self.range.count) return @"";
    id value = self.range[row];
    if ([value isKindOfClass:[NSDictionary class]] && self.rangeKey) {
        value = [(NSDictionary *) value btd_stringValueForKey:self.rangeKey];
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    return @"";
}

- (NSArray<NSNumber *> *)valuesRow {
    if (self.value) {
        return @[self.value];
    }
    return @[];
}

@end

@implementation BDXPickerMultiSelectorSource

- (NSInteger)numberOfComponents {
    if (self.range == nil || [self.range isEqual:[NSNull null]]) {
        return 0;
    }
    return self.range.count;
}
- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    if (component >= self.numberOfComponents) {
        NSCAssert(0, @"out of bounds");
        return 0;
    }
    return self.range[component].count;
}
- (NSString *)stringValueForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component >= self.numberOfComponents) {
        NSCAssert(0, @"out of bounds");
        return @"";
    }
    if (row > [self numberOfRowsInComponent:component]) {
        NSCAssert(0, @"out of bounds");
        return @"";
    }

    id value = self.range[component][row];
    if ([value isKindOfClass:[NSDictionary class]] && self.rangeKey) {
        value = [(NSDictionary *) value btd_stringValueForKey:self.rangeKey[component]];
    }
    
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    return [NSString stringWithFormat:@"%@", value];
}

- (NSArray<NSNumber *> *)valuesRow {
    if (self.value) {
        return self.value;
    }
    return @[];
}

@end


@interface BDXPickerDateTimeSource ()
@property (nonatomic) NSCalendar *calendar;
@property (nonatomic) NSArray *years;
@property (nonatomic) NSArray *months;


@end

@implementation BDXPickerDateTimeSource

- (instancetype)init {
    self = [super init];
    
    
    return self;
}

- (NSDate *)startDate {
    if (BTD_isEmptyString(_start)) {
        static NSDate *sStartDate = nil;
        if (!sStartDate) {
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            dateComponents.year = 1900;
            NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            sStartDate = [gregorianCalendar dateFromComponents:dateComponents];
        }
        return sStartDate;
    }
    return [self dateFromStringValue:_start];
}

- (NSDate *)endDate {
    if (BTD_isEmptyString(_end)) {
        return [NSDate distantPast];
    }
    return [self dateFromStringValue:_end];
}

- (NSDate *)valueDate {
    if (BTD_isEmptyString(_value)) {
        return nil;
    }
    return [self dateFromStringValue:_value];
}

- (NSDate *)dateFromStringValue:(NSString *)value
{
    // 猜测时间格式
    if ([self.mode isEqualToString:kBDXPickerSourceModeDate] || [self.mode isEqualToString:kBDXPickerSourceModeDateLegacy]) {
        NSScanner *scanner = [NSScanner scannerWithString:value];
        scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:self.separator?:@"-"];
        NSInteger n;
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        if ([scanner scanInteger:&n]) {
            dateComponents.year = n;
            if ([scanner scanInteger:&n]) {
                dateComponents.month = n;
                if ([scanner scanInteger:&n]) {
                    dateComponents.day = n;
                }
            }
        }
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDate *capturedDate = [calendar dateFromComponents:dateComponents];
        return capturedDate;
    } else if ([self.mode isEqualToString:kBDXPickerSourceModeTime] || [self.mode isEqualToString:kBDXPickerSourceModeTimeLegacy]) {
        NSScanner *scanner = [NSScanner scannerWithString:value];
        scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:self.separator?:@":"];
        NSInteger n;
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        if ([scanner scanInteger:&n]) {
            dateComponents.hour = n;
            if ([scanner scanInteger:&n]) {
                dateComponents.minute = n;
            }
        }
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *capturedDate = [calendar dateFromComponents:dateComponents];
        return capturedDate;
    }
    return nil;
}

- (NSInteger)startYear {
    if (BTD_isEmptyString(_start)) {
        return kStartYear;
    }
    NSDate *date = [self dateFromStringValue:_start];
    if (date) {
        return date.btd_year;
    } else {
        return kStartYear;
    }
}

- (NSInteger)endYear {
    if (BTD_isEmptyString(_end)) {
        return kEndYear;
    }
    NSDate *date = [self dateFromStringValue:_end];
    if (date) {
        return date.btd_year;
    } else {
        return kEndYear;
    }
}

- (NSArray *)years {
    if (!_years) {
        _years = [[NSMutableArray alloc] init];
        for (NSInteger i = self.startYear; i <= self.endYear; i++) {
            [(NSMutableArray *)_years addObject:BDXElementPluralLocalizedString(BDXElementLocalizedStringKeyYear, @"%ld years", 1, i)];
        }
    }
    return _years;
}

- (NSArray *)months {
    if (!_months) {
        _months = [[NSMutableArray alloc] init];
        for (NSInteger i = self.startMonth; i <= self.endMonth; i++) {
            [(NSMutableArray *)_months addObject:BDXElementPluralLocalizedString(BDXElementLocalizedStringKeyMonth, @"%ld months", 1, i - 1)];
        }
    }
    return _months;
}

- (NSInteger)startMonth {
    if (self.years.count == 1 && !BTD_isEmptyString(_start)) {
        NSDate *date = [self dateFromStringValue:_start];
        if (date) {
            return date.btd_month + 1;
        }
    }
    return kStartMonth;
}

- (NSInteger)endMonth {
    if (self.years.count == 1 && !BTD_isEmptyString(_end)) {
        NSDate *date = [self dateFromStringValue:_end];
        if (date) {
            return date.btd_month + 1;
        }
    }
    return kEndMonth;
}

- (NSInteger)numberOfComponents {
    if ([self.fields isEqualToString:@"year"]) {
        return 1;
    }
    if ([self.fields isEqualToString:@"month"]) {
        return 2;
    }
    return 0;
}

- (NSInteger)numberOfRowsInComponent:(NSInteger)component {
    if (component == 0)
        return self.years.count;
    if (component == 1)
        return self.months.count;
    return 0;
}

- (NSString *)stringValueForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0)
        return self.years[row];
    if (component == 1)
        return self.months[row];
    
    return @"";
}

- (BOOL)isYearAndMonth {
    return [self.fields isEqualToString:@"year"] || [self.fields isEqualToString:@"month"];
}

- (NSArray<NSNumber *> *)valuesRow {
    if ([self isYearAndMonth] && !BTD_isEmptyString(self.value)) {
        NSDate *vdate = [self dateFromStringValue:self.value];
        NSInteger year = vdate.btd_year;
        NSInteger month = vdate.btd_month + 1;
        if ([self.fields isEqualToString:@"year"]) {
            if (year >= self.startYear && year <= self.endYear)
                return @[@(year-self.startYear)];
        }
        if ([self.fields isEqualToString:@"month"]) {
            if ((year >= self.startYear && year <= self.endYear) && (month >= self.startMonth && month <= self.endMonth))
                return @[@(year-self.startYear),@(month-self.startMonth)];
        }
    }
    return @[];
}

@end
