//
//  HMDMonitorCallbackObject.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/20.
//

#import "HMDMonitorCallbackObject.h"

@interface HMDMonitorCallbackObject ()

@property (nonatomic, copy, nullable, readwrite) HMDMonitorCallback callBack;
@property (nonatomic, copy, nullable, readwrite) NSString *moduleName;

@end

@implementation HMDMonitorCallbackObject

- (instancetype)initWithModuleName:(NSString *)moduleName callBack:(HMDMonitorCallback)callback {
    self = [super init];
    if (self) {
        _moduleName = [moduleName copy];
        if (callback) {
            _callBack = [callback copy];
        }
    }

    return self;
}

@end
