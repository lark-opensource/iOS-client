//
//  BDPStorageStrategy.m
//  Timor
//
//  Created by houjihu on 2020/5/14.
//

#import "BDPStorageStrategy.h"
#import <ECOInfra/BDPLog.h>

@implementation BDPStorageStrategy

+ (NSString *)rootDirectoryPathForType:(BDPType)type {
    NSString *path;
    switch (type) {
        case BDPTypeNativeApp:{
            path = @"tma";
            break;
        }
        case BDPTypeWebApp: {
            path = @"twebapp";
            break;
        }
        case BDPTypeNativeCard: {
            path = @"tcard";
            break;
        }
        case BDPTypeBlock: {
            path = @"tblock";
            break;
        }
        case BDPTypeDynamicComponent: {
            path = @"dycomponent";
            break;
        }
        case BDPTypeSDKMsgCard: {
            path = @"msgcard";
            break;
        }
        case BDPTypeThirdNativeApp: {
            path = @"thirdnativeapp";
            break;
        }
        case BDPTypeUnknown:
        default: {
            path = @"tdefault";
            NSString *msg = [NSString stringWithFormat:@"Wrong type for rootDirectoryPath: %@", @(type)];
            BDPLogError(msg);
            NSAssert(NO, msg);
            break;
        }
    }
    return path;
}

@end
