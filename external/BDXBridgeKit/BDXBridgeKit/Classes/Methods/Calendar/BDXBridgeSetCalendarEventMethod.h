//
//  BDXBridgeSetCalendarEventMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeSetCalendarEventMethod : BDXBridgeMethod

@end

@interface BDXBridgeSetCalendarEventMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *eventID;
@property (nonatomic, strong) NSNumber *startDate;
@property (nonatomic, strong) NSNumber *endDate;
@property (nonatomic, strong) NSNumber *alarmOffset;
@property (nonatomic, assign) BOOL allDay;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *url;

@end

@interface BDXBridgeSetCalendarEventMethodResultModel : BDXBridgeModel

@property (nonatomic, copy) NSString *eventID;

@end

NS_ASSUME_NONNULL_END
