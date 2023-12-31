//
//  HMDInjectedInfo+NetworkSchedule.h
//  Heimdallr
//
//  Created by 王佳乐 on 2019/4/17.
//

#import "HMDInjectedInfo.h"

extern NSString * _Nonnull const kHMDNetworkScheduleNotification;

@interface HMDInjectedInfo (NetworkSchedule)
@property (nonatomic, strong, nullable) NSNumber *disableNetworkRequest;/** 控制Heimdallr 网络请求的时机，默认为 NO */
@end

