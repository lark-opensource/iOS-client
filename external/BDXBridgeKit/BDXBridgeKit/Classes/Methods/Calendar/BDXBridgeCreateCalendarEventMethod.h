//
//  BDXBridgeCreateCalendarEventMethod.h
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXBridgeCreateCalendarEventFrequencyType) {
    BDXBridgeCreateCalendarEventFrequencyTypeDaily,
    BDXBridgeCreateCalendarEventFrequencyTypeWeekly,
    BDXBridgeCreateCalendarEventFrequencyTypeMonthly,
    BDXBridgeCreateCalendarEventFrequencyTypeYearly
};

@interface BDXBridgeCreateCalendarEventMethod : BDXBridgeMethod

@end

@interface BDXBridgeCreateCalendarEventMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, assign) BDXBridgeCreateCalendarEventFrequencyType repeatFrequency;
@property (nonatomic, assign) NSInteger repeatInterval;
@property (nonatomic, assign) NSInteger repeatCount;
@property (nonatomic, strong) NSNumber *startDate;
@property (nonatomic, strong) NSNumber *endDate;
@property (nonatomic, strong) NSNumber *alarmOffset;
@property (nonatomic, assign) BOOL allDay;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END
