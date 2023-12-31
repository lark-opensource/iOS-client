//
//  ACCRecorderTextModeStickerContainerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/10/19.
//

#import "ACCRecorderTextModeStickerContainerConfig.h"
#import <CreativeKitSticker/ACCGestureResponsibleStickerView.h>
#import "ACCStickerPluginConfig.h"
#import "ACCStickerSafeAreaView.h"
#import "ACCStickerDeletePlugin.h"
#import "ACCStickerAdsorbingView.h"
#import "ACCStickerPreviewView.h"
#import "ACCStickerAngleAdsorbingPlugin.h"
#import "ACCStickerHighlightMomentPlugin.h"
#import "ACCStickerAutoCaptionsPlugin.h"

@interface ACCRecorderTextModeStickerContainerConfig ()

@property (nonatomic, copy) NSArray<id<ACCStickerContainerPluginProtocol>> *stickerPlugins;

@end

@implementation ACCRecorderTextModeStickerContainerConfig
@synthesize contextId;
@synthesize stickerHierarchyComparator;
@synthesize ignoreMaskRadiusForXScreen;

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    ACCRecorderTextModeStickerContainerConfig *config = [[[self class] allocWithZone:zone] init];
    config.contextId = self.contextId;
    config.stickerHierarchyComparator = self.stickerHierarchyComparator;
    config.ignoreMaskRadiusForXScreen = self.ignoreMaskRadiusForXScreen;
    
    return config;
}

#pragma mark -
- (instancetype)init
{
    self = [super init];
    
    if (self) {
        NSMutableArray *allPlugins = [[NSMutableArray alloc] init];
        [[ACCRecorderTextModeStickerContainerConfig pluginList] enumerateObjectsUsingBlock:^(Class<ACCStickerContainerPluginProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id<ACCStickerContainerPluginProtocol> plugin = [obj createPlugin];
            if (plugin) {
                [allPlugins addObject:plugin];
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
        [ACCStickerSafeAreaView class],
        [ACCStickerDeletePlugin class],
        [ACCStickerAdsorbingView class],
        [ACCStickerPreviewView class],
        [ACCStickerAngleAdsorbingPlugin class],
        [ACCStickerHighlightMomentPlugin class],
        [ACCStickerAutoCaptionsPlugin class]
    ];
}

- (nonnull Class<ACCStickerProtocol>)stickerFactoryClass
{
    return [ACCGestureResponsibleStickerView class];
}

- (nonnull Class<ACCStickerPluginProtocol>)stickerPluginConfigClass
{
    return [ACCStickerPluginConfig class];
}

@end
