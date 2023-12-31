//
//  BDPPluginXScreenCustomImpl.m
//  EEMicroAppSDK
//
//  Created by qianhongqiang on 2022/09/05.
//

#import "BDPPluginXScreenCustomImpl.h"

#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPGadget/OPGadget-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

@implementation BDPPluginXScreenCustomImpl

+ (instancetype)sharedPlugin {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (BOOL)isXscreenModeWhileLaunchingForUniqueID:(BDPUniqueID *)uniqueID {
    OPGadgetContainerMountData *currentMountData = [self _currentMountDataForUniqueID:uniqueID];
    return currentMountData && currentMountData.xScreenData;
}

- (nullable NSString *)XScreenPresentationStyleWhileLaunchingForUniqueID:(BDPUniqueID *)uniqueID {
    OPGadgetContainerMountData *currentMountData = [self _currentMountDataForUniqueID:uniqueID];
    if (currentMountData) {
        return currentMountData.xScreenData.presentationStyle;
    }
    return nil;
}

-(nullable OPGadgetContainerMountData *)_currentMountDataForUniqueID:(BDPUniqueID *)uniqueID {
    OPBaseContainer *container = [[OPApplicationService current] getContainerWithUniuqeID:uniqueID];
    if (container && [container isKindOfClass:[OPBaseContainer class]]) {
        OPGadgetContainerMountData *currentMountData = [container containerContext].currentMountData;
        if ([currentMountData isKindOfClass:[OPGadgetContainerMountData class]]) {
            return currentMountData;
        }
    }
    return nil;
}

@end
