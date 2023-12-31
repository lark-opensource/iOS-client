//
//  ACCVideoEditStickerContainerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/10/7.
//

#import "ACCVideoEditStickerContainerConfig.h"
#import <CreativeKitSticker/ACCGestureResponsibleStickerView.h>
#import "ACCStickerPluginConfig.h"
#import "ACCStickerSafeAreaView.h"
#import "ACCStickerDeletePlugin.h"
#import "ACCStickerAdsorbingView.h"
#import "ACCStickerPreviewView.h"
#import "ACCStickerAngleAdsorbingPlugin.h"
#import "ACCStickerHighlightMomentPlugin.h"
#import "ACCStickerAutoCaptionsPlugin.h"
#import "ACCInfoStickerPinPlugin.h"
#import "ACCLyricsStickerUpdateFramePlugin.h"
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "ACCStickerDeSelectPlugin.h"
#import "ACCStickerLimitEdgeView.h"
#import "ACCImageAlbumSafeAreaPlugin.h"

@interface ACCVideoEditStickerContainerConfig ()

@property (nonatomic, copy) NSArray<id<ACCStickerContainerPluginProtocol>> *stickerPlugins;

@end

@implementation ACCVideoEditStickerContainerConfig
@synthesize contextId;
@synthesize stickerHierarchyComparator;
@synthesize ignoreMaskRadiusForXScreen;

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    ACCVideoEditStickerContainerConfig *config = [[[self class] allocWithZone:zone] init];
    config.contextId = self.contextId;
    config.stickerHierarchyComparator = self.stickerHierarchyComparator;
    config.editStickerService = self.editStickerService;
    config.ignoreMaskRadiusForXScreen = self.ignoreMaskRadiusForXScreen;
    
    return config;
}

#pragma mark -

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        NSMutableArray *allPlugins = [[NSMutableArray alloc] init];
        [[ACCVideoEditStickerContainerConfig pluginList] enumerateObjectsUsingBlock:^(Class<ACCStickerContainerPluginProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
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
    NSMutableArray *plugins = [NSMutableArray arrayWithArray:
                               @[
                                   [ACCStickerDeletePlugin class],
                                   [ACCStickerAdsorbingView class],
                                   [ACCStickerSafeAreaView class],
                                   [ACCStickerPreviewView class],
                                   [ACCStickerAngleAdsorbingPlugin class],
                                   [ACCStickerHighlightMomentPlugin class],
                                   [ACCStickerAutoCaptionsPlugin class],
                                   [ACCInfoStickerPinPlugin class],
                                   [ACCLyricsStickerUpdateFramePlugin class],
                                   [ACCStickerDeSelectPlugin class],
                               ]];
    return plugins;
}

- (nonnull Class<ACCStickerProtocol>)stickerFactoryClass
{
    return [ACCGestureResponsibleStickerView class];
}

- (nonnull Class<ACCStickerPluginProtocol>)stickerPluginConfigClass
{
    return [ACCStickerPluginConfig class];
}

#pragma mark - Setter

- (void)setEditStickerService:(id<ACCEditStickerProtocol>)editStickerService
{
    _editStickerService = editStickerService;
    [self.stickerPlugins enumerateObjectsUsingBlock:^(id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCInfoStickerPinPlugin.class]) {
            ACCInfoStickerPinPlugin *pinPlugin = (id)obj;
            pinPlugin.editStickerService = editStickerService;
        } else if ([obj isKindOfClass:ACCLyricsStickerUpdateFramePlugin.class]) {
            ((ACCLyricsStickerUpdateFramePlugin *)obj).editStickerService = editStickerService;
        }
    }];
}

#pragma mark - Private APIs

- (void)removePluginWithClass:(Class)pluginClass
{
    if (pluginClass == Nil) {
        return;
    }
    
    NSMutableArray *copyPlugins = [NSMutableArray arrayWithArray:self.stickerPlugins];
    [self.stickerPlugins enumerateObjectsUsingBlock:^(id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:pluginClass]) {
            [copyPlugins removeObject:obj];
            *stop = YES;
        }
    }];
    
    self.stickerPlugins = copyPlugins;
}

- (void)removePluginExceptClasses:(NSArray<Class> *)exceptPluginClass
{
    if (exceptPluginClass.count == 0) {
        return;
    }
    
    self.stickerPlugins = [self.stickerPlugins btd_filter:^BOOL(id<ACCStickerContainerPluginProtocol>  _Nonnull obj) {
        return [exceptPluginClass btd_firstIndex:^BOOL(Class  _Nonnull cls) {
            return [obj isKindOfClass:cls];
        }] != NSNotFound;
    }];
}

#pragma mark - Public APIs

- (void)addPlugin:(id<ACCStickerContainerPluginProtocol>)plugin
{
    if (plugin == nil) {
        return;
    }
    
    NSMutableArray *stickerPlugins = [NSMutableArray arrayWithCapacity:self.stickerPlugins.count + 1];
    [stickerPlugins addObjectsFromArray:self.stickerPlugins];
    [stickerPlugins addObject:plugin];
    self.stickerPlugins = stickerPlugins;
}

- (void)reomoveSafeAreaPlugin
{
    [self removePluginWithClass:[ACCStickerSafeAreaView class]];
}

- (void)removeAdsorbingPlugin
{
    [self removePluginWithClass:[ACCStickerAdsorbingView class]];
    [self removePluginWithClass:[ACCStickerAngleAdsorbingPlugin class]];
}

- (void)removePreviewViewPlugin
{
    [self removePluginWithClass:[ACCStickerPreviewView class]];
}

- (void)removePluginsExceptEditLyrics
{
    [self removePluginExceptClasses:@[
        [ACCStickerAdsorbingView class],
        [ACCStickerAngleAdsorbingPlugin class],
        [ACCLyricsStickerUpdateFramePlugin class]
    ]];
}

- (void)changeAlbumImagePluginsWithMaterialSize:(CGSize)size
{
    [self removePluginExceptClasses:@[
        [ACCStickerAdsorbingView class],
        [ACCStickerPreviewView class],
        [ACCStickerAngleAdsorbingPlugin class],
        [ACCStickerDeSelectPlugin class],
    ]];
    
    ACCImageAlbumSafeAreaPlugin *imageAlbumSafeAreaPlugin = [ACCImageAlbumSafeAreaPlugin createPlugin];
    imageAlbumSafeAreaPlugin.materialSize = size;
    [self addPlugin:imageAlbumSafeAreaPlugin];
    [self addPlugin:[ACCStickerLimitEdgeView createPlugin]];
}

- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model
{
    [self.stickerPlugins enumerateObjectsUsingBlock:^(id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCStickerPreviewView.class]) {
            ACCStickerPreviewView *previewView = (id)obj;
            [previewView updateMusicCoverWithMusicModel:model];
            *stop = YES;
        }
    }];
}

@end
