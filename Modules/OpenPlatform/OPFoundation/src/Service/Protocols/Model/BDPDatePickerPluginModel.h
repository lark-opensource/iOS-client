//
//  BDPDatePickerPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/4.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 时间选择器的数据模型
 */
@interface BDPDatePickerPluginModel : BDPBaseJSONModel
/// 开始时间
@property (nonatomic, strong, nullable) NSDate *startDate;
/// 结束时间
@property (nonatomic, strong, nullable) NSDate *endDate;
/// 当前时间
@property (nonatomic, strong) NSDate *currentDate;
/// 模式 ‘time’ or 'data'
@property (nonatomic, strong) NSString *mode;
/// 'year', 'month', 'day'
@property (nonatomic, strong) NSString *fields;
/// frame
@property (nonatomic, assign) CGRect frame;
/// 时区，默认是上海时区 - 'Asia/Shanghai'
@property (nonatomic, strong, readonly) NSTimeZone *timeZone;

- (NSString *)stringFromDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
