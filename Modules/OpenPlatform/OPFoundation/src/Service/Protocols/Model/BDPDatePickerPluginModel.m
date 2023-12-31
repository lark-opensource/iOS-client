//
//  BDPDatePickerPluginModel.m
//  Timor
//
//  Created by MacPu on 2018/11/4.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import "BDPDatePickerPluginModel.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface BDPDatePickerPluginModel ()

@property (nonatomic, strong, readwrite) NSTimeZone *timeZone;

@end

@implementation BDPDatePickerPluginModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        [self computeFrameWithDictionary:dict];
        [self setupDateWithDictionary:dict];
    }
    
    return self;
}

- (void)computeFrameWithDictionary:(NSDictionary *)dict
{
    NSDictionary *position = [dict bdp_dictionaryValueForKey:@"style"];
    
    if (!position.count) {
        self.frame = CGRectNull;
        return;
    }
    
    CGFloat top = ceilf([position bdp_floatValueForKey:@"top"]);
    CGFloat left = ceilf([position bdp_floatValueForKey:@"left"]);
    CGFloat width = ceilf([position bdp_floatValueForKey:@"width"]);
    CGFloat height = ceilf([position bdp_floatValueForKey:@"height"]);
    
    self.frame = CGRectMake(left, top, width, height);
}

- (void)setupDateWithDictionary:(NSDictionary *)dict
{
    NSDateFormatter *formatter = [self setupDateFormatter];
    NSDictionary *range = [dict bdp_dictionaryValueForKey:@"range"];
    if (!range.count) {
        return;
    }
    
    NSString *startTimeString = [range bdp_stringValueForKey:@"start"];
    startTimeString = [self dateStringForString:startTimeString];
    NSString *endTimeString = [range bdp_stringValueForKey:@"end"];
    endTimeString = [self dateStringForString:endTimeString];
    NSString *currentDateString = [dict bdp_stringValueForKey:@"current"];
    currentDateString = [self dateStringForString:currentDateString];
    self.startDate = [formatter dateFromString:startTimeString];
    self.endDate = [formatter dateFromString:endTimeString];
    self.currentDate = [formatter dateFromString:currentDateString] ?: [NSDate date];
}

- (NSDateFormatter *)setupDateFormatter {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if ([self.mode isEqualToString:@"time"]) {
        [formatter setDateFormat:@"HH:mm"];
    } else if ([self.fields isEqualToString:@"day"]) {
        [formatter setDateFormat:@"yyyy-MM-dd"];
    } else if ([self.fields isEqualToString:@"month"]) {
        [formatter setDateFormat:@"yyyy-MM"];
    } else if ([self.fields isEqualToString:@"year"]) {
        [formatter setDateFormat:@"yyyy"];
    }
    formatter.defaultDate = [NSDate date];
    [formatter setTimeZone:self.timeZone];
    return formatter;
}

- (NSString *)stringFromDate:(NSDate *)date
{
    if (!date) {
        return nil;
    }
    NSDateFormatter *formatter = [self setupDateFormatter];
    NSString *dateString = [formatter stringFromDate:date];
    return dateString;
}

- (NSString *)dateStringForString:(NSString *)rawDateString
{
    NSInteger componentCount = 1;
    NSString *sperator = @"-";
    if ([self.mode isEqualToString:@"time"]) {
        componentCount = 2;
        sperator = @":";
    } else if ([self.fields isEqualToString:@"day"]) {
        componentCount = 3;
    } else if ([self.fields isEqualToString:@"month"]) {
        componentCount = 2;
    } else if ([self.fields isEqualToString:@"year"]) {
        componentCount = 1;
    }
    
    NSArray<NSString *> *components = [rawDateString componentsSeparatedByString:sperator];
    NSInteger toIndex = MIN(componentCount, components.count);
    components = [components subarrayWithRange:NSMakeRange(0, toIndex)];
    
    NSString *newString = [components componentsJoinedByString:sperator];
    
    return newString;
}

- (NSTimeZone *)timeZone
{
    if (!_timeZone) {
        _timeZone = [NSTimeZone systemTimeZone];
    }
    
    return _timeZone;
}

@end
