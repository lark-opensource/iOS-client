//
//  TSPKExternalLogReceiver.m
//  Musically
//
//  Created by ByteDance on 2022/12/19.
//

#import "TSPKExternalLogReceiver.h"
#import "TSPKSignalManager+log.h"
#import "TSPKConfigs.h"

@implementation TSPKExternalLogReceiver

+ (BOOL)enableReceiveExternalLog {
    return [[TSPKConfigs sharedConfig] enableReceiveExternalLog];
}

+ (void)externalLogWithTag:(nullable NSString *)tag content:(nullable NSString *)content {
    [TSPKSignalManager addLogWithTag:tag content:content];
}

@end
