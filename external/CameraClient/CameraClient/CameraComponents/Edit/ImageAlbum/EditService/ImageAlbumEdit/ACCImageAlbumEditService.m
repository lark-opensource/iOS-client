//
//  ACCImageAlbumEditService.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageAlbumEditService.h"
#import <CreationKitRTProtocol/ACCEditSessionBuilderProtocol.h>
#import <objc/runtime.h>
#import <IESInject/IESInject.h>
#import <Mantle/EXTKeyPathCoding.h>
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import "ACCImageAlbumEditorSession.h"

#import "ACCEditImageAlbumCaptureFrameWraper.h"
#import "ACCImageAlbumEditFilterWraper.h"
#import "ACCImageAlbumEditStickerWraper.h"
#import "ACCEditImageAlbumMixedWraper.h"
#import "ACCImageAlbumEditHDRWraper.h"
#import "ACCImageAlbumEditorMacro.h"

static NSString *ACCImageAlbumEditServiceProtocolKey = @"ACCImageAlbumEditServiceProtocolKey";
static NSString *ACCImageAlbumEditServiceClassKey = @"ACCImageAlbumEditServiceClassKey";

@interface ACCImageAlbumEditService ()

@property (nonatomic, strong) NSMutableArray<id<ACCEditWrapper>> *plugins;

@property (nonatomic, strong) id<ACCImageAlbumEditorSessionProtocol> editSession;
@property (nonatomic, weak) id<IESServiceProvider> serviceResolver;
@property (nonatomic, strong) ACCCameraSubscription *subscription;

@property (nonatomic, strong) id<ACCEditFilterProtocol> filter;
@property (nonatomic, strong) id<ACCEditStickerProtocol> sticker;
@property (nonatomic, strong) id<ACCEditImageAlbumMixedProtocol>imageAlbumMixed;
@property (nonatomic, strong) id<ACCImageEditHDRProtocol> imageEditHDR;
@property (nonatomic, strong) id<ACCEditCaptureFrameProtocol> captureFrame;

@end

@implementation ACCImageAlbumEditService
@synthesize mediaContainerView = _mediaContainerView;
@synthesize editBuilder = _editBuilder;
@synthesize effect, audioEffect, preview, captureFrame, canvas, hdr, beauty; // 图集模式下不需要
@synthesize multiTrack; // ve 不实现支持多轨编辑

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)propertyForProtocol
{
    return @{
        @keypath(self, filter): @{
                ACCImageAlbumEditServiceProtocolKey: @protocol(ACCEditFilterProtocol),
                ACCImageAlbumEditServiceClassKey: ACCImageAlbumEditFilterWraper.class
        },
        @keypath(self, sticker): @{
                ACCImageAlbumEditServiceProtocolKey: @protocol(ACCEditStickerProtocol),
                ACCImageAlbumEditServiceClassKey: ACCImageAlbumEditStickerWraper.class
        },
        @keypath(self, imageAlbumMixed): @{
                ACCImageAlbumEditServiceProtocolKey: @protocol(ACCEditImageAlbumMixedProtocol),
                ACCImageAlbumEditServiceClassKey: ACCEditImageAlbumMixedWraper.class
        },
        @keypath(self, imageEditHDR): @{
                ACCImageAlbumEditServiceProtocolKey: @protocol(ACCImageEditHDRProtocol),
                ACCImageAlbumEditServiceClassKey: ACCImageAlbumEditHDRWraper.class
        },
        @keypath(self, captureFrame): @{
                ACCImageAlbumEditServiceProtocolKey: @protocol(ACCEditCaptureFrameProtocol),
                ACCImageAlbumEditServiceClassKey: ACCEditImageAlbumCaptureFrameWraper.class
        },
    };
}

- (void)configResolver:(id<IESServiceProvider>)resolver
{
    _serviceResolver = resolver;
    
    [[self propertyForProtocol] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *, id> * _Nonnull obj, BOOL * _Nonnull stop) {
        Protocol *theProtocol = (Protocol *)obj[ACCImageAlbumEditServiceProtocolKey];
        Class theClass = (Class)obj[ACCImageAlbumEditServiceClassKey];
        
        id resolveObj = [resolver resolveObject:theProtocol];
        if ([[resolveObj class] isEqual:theClass]) {
            [self setValue:resolveObj forKey:key];
        } else {
            ACCImageEditModeAssertUnsupportFeatureForReason(@"resolverObj is not kind of %@", theClass);
        }
    }];
}

- (instancetype)initForPublish
{
    self = [super init];
    
    if (self) {
        [self buildPlugins];
    }
    
    return self;
}

- (void)buildPlugins
{
    [[self propertyForProtocol] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *, id> * _Nonnull obj, BOOL * _Nonnull stop) {
        Protocol *theProtocol = (Protocol *)obj[ACCImageAlbumEditServiceProtocolKey];
        Class theClass = (Class)obj[ACCImageAlbumEditServiceClassKey];
        
        id resolveObj = [[theClass alloc] init];
        if ([resolveObj conformsToProtocol:theProtocol]) {
            [self setValue:resolveObj forKey:key];
            [self.plugins addObject:resolveObj];
        } else {
            ACCImageEditModeAssertUnsupportFeatureForReason(@"theClass doesn't conform to %@", theProtocol);
        }
    }];
}

#pragma mark - getter

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}


#pragma mark - public

- (void)buildEditSession
{
    self.editSession = [self.editBuilder buildEditSession].imageEditSession;
    
    [self.plugins enumerateObjectsUsingBlock:^(id<ACCEditWrapper>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj setEditSessionProvider:self.editBuilder];
    }];
    
    @weakify(self);
    [self.subscription performEventSelector:@selector(onCreateEditSessionCompletedWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
        @strongify(self);
        [handler onCreateEditSessionCompletedWithEditService:self];
    }];
    
    [self.editSession setOnFirstImageEditorRendered:^(void) {
        @strongify(self);
        [self.subscription performEventSelector:@selector(firstRenderWithEditService:) realPerformer:^(id<ACCEditSessionLifeCircleEvent> handler) {
            @strongify(self);
            [handler firstRenderWithEditService:self];
        }];
    }];
}

- (NSMutableArray<id<ACCEditWrapper>> *)plugins
{
    if (!_plugins) {
        _plugins = @[].mutableCopy;
    }
    return _plugins;
}

- (void)addSubscriber:(id<ACCEditSessionLifeCircleEvent>)subscriber
{
    [self.subscription addSubscriber:subscriber];
}

- (UIView <ACCMediaContainerViewProtocol> *)mediaContainerView
{
    return self.editBuilder.mediaContainerView;
}

- (void)resetPlayerAndPreviewEdge
{
    
}

- (void)dismissPreviewEdge {
}



@end
