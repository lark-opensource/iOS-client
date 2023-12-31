//
//  AWEStickerApplyHandlerContainer.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/5/8.
//

#import "AWEStickerApplyHandlerContainer.h"

@implementation AWEStickerApplyBaseHandler
@end

@interface AWEStickerApplyHandlerContainer ()

@property (nonatomic, strong) NSMutableArray<id<AWEStickerApplyHandlerProtocol>> *handlers;

@property (nonatomic, strong, readwrite) id<ACCCameraService> cameraService;
@property (nonatomic, strong, readwrite) id<ACCRecordPropService> propService;
@property (nonatomic, strong, readwrite) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong, readwrite) id<ACCRecordConfigService> configService;
@property (nonatomic, strong, readwrite) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong, readwrite) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong, readwrite) id<ACCFilterService> filterService;
@property (nonatomic, weak, readwrite) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong, readwrite) id<IESServiceProvider> serviceProvider;
@property (nonatomic, strong, readwrite) id<ACCRecordModeFactory> modeFactory;

//viewModel
@property (nonatomic, strong, readwrite) ACCPropViewModel *propViewModel;

@property (nonatomic, weak, readwrite) UIViewController *containerViewController;
@property (nonatomic, weak, readwrite) id<ACCRecorderViewContainer> viewContainer;

@end

@implementation AWEStickerApplyHandlerContainer
@synthesize layoutManager = _layoutManager;

- (instancetype)initWithCameraService:(id<ACCCameraService>)cameraService
                          propService:(id<ACCRecordPropService>)propService
                          flowService:(id<ACCRecordFlowService>)flowService
                        configService:(id<ACCRecordConfigService>)configService
                    switchModeService:(id<ACCRecordSwitchModeService>)switchModeService
                         trackService:(id<ACCRecordTrackService>)trackService
                        filterService:(id<ACCFilterService>)filterService
                      serviceProvider:(id<IESServiceProvider>)serviceProvider
                        propViewModel:(ACCPropViewModel *)propViewModel
              containerViewController:(UIViewController *)containerViewController
                        viewContainer:(id<ACCRecorderViewContainer>)viewContainer
                          modeFactory:(id<ACCRecordModeFactory>)modeFactory
{
    if (self = [super init]) {
        _cameraService = cameraService;
        _propService = propService;
        _flowService = flowService;
        _configService = configService;
        _switchModeService = switchModeService;
        _trackService = trackService;
        _filterService = filterService;
        _serviceProvider = serviceProvider;
        _propViewModel = propViewModel;
        _modeFactory = modeFactory;
        _karaokeService = IESOptionalInline(serviceProvider, ACCKaraokeService);
        _containerViewController = containerViewController;
        _viewContainer = viewContainer;
        _isExposePanelEnabled = NO;
    }
    return self;
}

- (NSMutableArray<id<AWEStickerApplyHandlerProtocol>> *)handlers {
    if (!_handlers) {
        _handlers = [[NSMutableArray alloc] init];
    }
    return _handlers;
}

- (void)addHandler:(id<AWEStickerApplyHandlerProtocol>)handler {
    if (handler) {
        handler.container = self;
        [self.handlers addObject:handler];
        if ([handler respondsToSelector:@selector(handlerDidBecomeActive)]) {
            [handler handlerDidBecomeActive];
        }
    }
}

- (void)componentDidAppear
{
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(componentDidAppear)]) {
            [handler componentDidAppear];
        }
    }
}

- (void)camera:(id<ACCCameraService>)cameraService willApplySticker:(IESEffectModel *)sticker {
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(camera:willApplySticker:)]) {
            [handler camera:cameraService willApplySticker:sticker];
        }
    }
}

- (void)camera:(id<ACCCameraService>)cameraService didApplySticker:(IESEffectModel *)sticker success:(BOOL)success
{
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(camera:didApplySticker:success:)]) {
            [handler camera:cameraService didApplySticker:sticker success:success];
        }
    }
}

- (void)camera:(id<ACCCameraService>)cameraService didRecvMessage:(IESMMEffectMessage *)message {
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(camera:didRecvMessage:)]) {
            [handler camera:cameraService didRecvMessage:message];
        }
    }
}

- (void)camera:(id<ACCCameraService>)cameraService didTakeAction:(IESCameraAction)action error:(NSError *)error data:(id)data {
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(camera:didTakeAction:error:data:)]) {
            [handler camera:cameraService didTakeAction:action error:error data:data];
        }
    }
}

- (void)setLayoutManager:(id<AWEStickerViewLayoutManagerProtocol>)layoutManager
{
    if (layoutManager == _layoutManager) {
        return;
    }
    _layoutManager = layoutManager;
    for (id<AWEStickerApplyHandlerProtocol> handler in self.handlers) {
        if ([handler respondsToSelector:@selector(didChangeLayoutManager:)]) {
            [handler didChangeLayoutManager:self.layoutManager];
        }
    }
}

- (id<AWEStickerViewLayoutManagerProtocol>)layoutManager
{
    if (_layoutManager) {
        return _layoutManager;
    }
    // waiting for refactor
    return self.propService.propPickerViewController;
}

@end
