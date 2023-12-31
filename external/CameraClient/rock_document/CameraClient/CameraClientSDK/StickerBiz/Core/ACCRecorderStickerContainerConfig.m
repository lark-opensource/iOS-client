//
//  ACCRecorderStickerContainerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import "ACCRecorderStickerContainerConfig.h"

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKitSticker/ACCGestureResponsibleStickerView.h>

#import "ACCStickerPluginConfig.h"
#import "ACCStickerSafeAreaView.h"
#import "ACCStickerDeletePlugin.h"
#import "ACCStickerAdsorbingView.h"
#import "ACCStickerPreviewView.h"
#import "ACCStickerAngleAdsorbingPlugin.h"
#import "ACCStickerHighlightMomentPlugin.h"
#import "ACCStickerAutoCaptionsPlugin.h"

/* --- Properties and Variables --- */

@interface ACCRecorderStickerContainerConfig ()

@property (nonatomic, copy) NSArray<id<ACCStickerContainerPluginProtocol>> *stickerPlugins;

@end

/* --- Implementation --- */

@implementation ACCRecorderStickerContainerConfig

@synthesize contextId;
@synthesize ignoreMaskRadiusForXScreen;
@synthesize stickerHierarchyComparator;

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSMutableArray *allPlugins = [[NSMutableArray alloc] init];
        [[ACCRecorderStickerContainerConfig pluginList] enumerateObjectsUsingBlock:^(Class<ACCStickerContainerPluginProtocol> _Nonnull obj,
                                                                                     NSUInteger idx,
                                                                                     BOOL * _Nonnull stop) {
            id<ACCStickerContainerPluginProtocol> plugin = [obj createPlugin];
            if (plugin) {
                [allPlugins acc_addObject:plugin];
            }
        }];
        _stickerPlugins = [allPlugins copy];
    }
    return self;
}

+ (NSArray *)pluginList
{
    // priority just Reflected in the order, but you still can do more logic with resortPluginPriority
    return @[
        [ACCStickerDeletePlugin class],
        [ACCStickerAdsorbingView class],
        [ACCStickerSafeAreaView class],
        [ACCStickerPreviewView class],
        [ACCStickerAngleAdsorbingPlugin class],
        [ACCStickerHighlightMomentPlugin class],
        [ACCStickerAutoCaptionsPlugin class]
    ];
}

#pragma mark - NSCopying

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    ACCRecorderStickerContainerConfig *config = [[[self class] allocWithZone:zone] init];
    config.contextId = self.contextId;
    config.stickerHierarchyComparator = self.stickerHierarchyComparator;
    config.ignoreMaskRadiusForXScreen = self.ignoreMaskRadiusForXScreen;
    
    return config;
}

#pragma mark - ACCStickerContainerConfigProtocol Methods

- (nonnull Class<ACCStickerProtocol>)stickerFactoryClass {
    return [ACCGestureResponsibleStickerView class];
}

- (nonnull Class<ACCStickerPluginProtocol>)stickerPluginConfigClass {
    return [ACCStickerPluginConfig class];
}

@end
