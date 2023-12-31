//
//  BDXBridgeReadCalendarEventMethod.h
//  BDXBridgeKit
//
//  Created by QianGuoQiang on 2021/4/27.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeReadCalendarEventMethod : BDXBridgeMethod

@end

@interface BDXBridgeReadCalendarEventMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *identifier;

@end

@interface BDXBridgeReadCalendarEventMethodResultModel : BDXBridgeModel

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
