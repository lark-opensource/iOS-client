//
//  BDWebSCCManager.m
//  BDWebKit
//
//  Created by bytedance on 6/20/22.
//

#import "BDWebSCCManager.h"
#import "BDWebKitSettingsManger.h"
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <BDAlogProtocol/BDAlogProtocol.h>

@implementation BDWebSCCManager

+ (instancetype)shareInstance {
    static BDWebSCCManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDWebSCCManager alloc] init];
    });
    return instance;
}

@end

