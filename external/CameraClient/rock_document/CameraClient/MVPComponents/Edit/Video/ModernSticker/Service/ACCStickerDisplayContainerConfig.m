//
//  ACCStickerDisplayContainerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/6/16.
//

#import "ACCStickerDisplayContainerConfig.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCStickerPluginConfig.h"
#import <CreativeKitSticker/ACCGestureResponsibleStickerView.h>

@implementation ACCStickerDisplayContainerConfig
@synthesize contextId = _contextId;
@synthesize stickerHierarchyComparator = _stickerHierarchyComparator;
@synthesize ignoreMaskRadiusForXScreen = _ignoreMaskRadiusForXScreen;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _stickerHierarchyComparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 integerValue]< [obj2 integerValue]) {
                return NSOrderedAscending;
            } else if ([obj1 integerValue] > [obj2 integerValue]){
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        };
        _ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCStickerDisplayContainerConfig *config = [[ACCStickerDisplayContainerConfig alloc] init];
    config.contextId = self.contextId;
    config.stickerHierarchyComparator = self.stickerHierarchyComparator;
    config.ignoreMaskRadiusForXScreen = self.ignoreMaskRadiusForXScreen;
    
    return config;
}

- (Class<ACCStickerProtocol>)stickerFactoryClass
{
    return [ACCGestureResponsibleStickerView class];
}

- (Class<ACCStickerPluginProtocol>)stickerPluginConfigClass
{
    return [ACCStickerPluginConfig class];
}

- (NSArray<id<ACCStickerContainerPluginProtocol>> *)stickerPlugins
{
    return @[];
}

@end
