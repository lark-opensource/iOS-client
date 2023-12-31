//
//  HMDMonitorCallbackObject.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/20.
//

#import <Foundation/Foundation.h>
#import "HMDMonitor.h"



@interface HMDMonitorCallbackObject : NSObject

@property (nonatomic, copy, nullable, readonly) HMDMonitorCallback callBack;
@property (nonatomic, copy, nullable, readonly) NSString *moduleName;

- (nonnull instancetype)initWithModuleName:(nullable NSString *)moduleName callBack:(nullable HMDMonitorCallback)callback;

@end

