//
//  MVPBaseServiceContainer+Creative.m
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import "MVPBaseServiceContainer+Creative.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCLogger.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "LVDLanguageService.h"
#import "LVDCacheService.h"
#import "LVDTrackService.h"
#import "LVDMonitorService.h"
#import "LVDToastService.h"
#import "LVDLogService.h"

@implementation MVPBaseServiceContainer (Creative)

IESProvidesSingleton(ACCLanguageProtocol)
{
    return [[LVDLanguageService alloc] init];
}

IESProvidesSingleton(ACCCacheProtocol)
{
    return [[LVDCacheService alloc] init];
}

IESProvidesSingleton(ACCLogProtocol)
{
    return [[LVDLogService alloc] init];
}

IESProvidesSingleton(ACCTrackProtocol)
{
    return [[LVDTrackService alloc] init];
}

IESProvidesSingleton(ACCMonitorProtocol)
{
    return [[LVDMonitorService alloc] init];
}

IESProvidesSingleton(ACCToastProtocol)
{
    return [[LVDToastService alloc] init];
}


@end
