//
//  HMDTTMonitorUserInfo.m
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/29.
//

#import "HMDTTMonitorUserInfo.h"

@interface HMDTTMonitorUserInfo ()

@property (nonatomic, copy, readwrite) NSString *appID;
@end

@implementation HMDTTMonitorUserInfo

- (instancetype)initWithAppID:(NSString *)appID {
    if (self = [super init]) {
        self.appID = appID;
    }
    return self;
}

@end
