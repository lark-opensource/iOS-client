//
//  ACCForegroundRenderComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/9/3.
//

#import "ACCForegroundRenderComponent.h"
#import <EffectSDK_iOS/BEFView.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "IESEffectModel+ACCForegroundRender.h"
#import "AWECameraPreviewContainerView.h"

@interface ACCForegroundRenderComponent () <BEFViewDelegate>

@property (nonatomic, strong) BEFView *view;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@property (nonatomic, strong, readonly) ACCPropViewModel *propViewModel;
@property (nonatomic, assign) BOOL appeared;

@end

@implementation ACCForegroundRenderComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer);
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService);

- (void)dealloc
{
    if (self.view) {
        [self p_hideView];
    }
}

- (void)loadComponentView
{
    if ([self propViewModel].currentSticker) {
        [self handleViewWithSticker:[self propViewModel].currentSticker];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    @weakify(self);
    [[self propViewModel].didSetCurrentStickerSignal.deliverOnMainThread subscribeNext:^(ACCRecordSelectEffectPack _Nullable pack) {
        @strongify(self);
        IESEffectModel *x = pack.first;
        [self handleViewWithSticker:x];
    }];
}

- (void)handleViewWithSticker:(IESEffectModel *)effectModel
{
    if ([effectModel.acc_foregroundRenderParams hasForeground]) {
        [self p_showViewForEffect:effectModel];
    } else {
        [self p_hideView];
    }
}

- (void)p_addObserverForView:(BEFView *)view
{
    let resignActive = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationWillResignActiveNotification object:nil] map:^id _Nullable(NSNotification * _Nullable value) {
        return @NO;
    }];
    
    let enterForground = [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] map:^id _Nullable(NSNotification * _Nullable value) {
        return @YES;
    }];
    
    let isActive = [RACSignal merge:@[resignActive, enterForground]];
    let isAppeared = RACObserve(self, appeared);
    @weakify(view);
    [[[RACSignal combineLatest:@[isActive, isAppeared]] takeUntil:view.rac_willDeallocSignal] subscribeNext:^(RACTuple * _Nullable x) {
        @strongify(view);
        if (view == nil) {
            return;
        }
        
        for (NSNumber *i in x) {
            BOOL needPause = ![i boolValue];
            if (needPause) {
                [view onPause];
                return;
            }
        }
        
        [view onResume];
    }];
}

- (void)componentDidUnmount
{
    if (self.view) {
        [self p_hideView];
    }
}

- (void)componentDidDisappear
{
    self.appeared = NO;
}

- (void)componentDidAppear
{
    self.appeared = YES;
}

- (void)p_showViewForEffect:(IESEffectModel *)effect
{
    ACCForegroundRenderParams *sdkParams = [effect acc_foregroundRenderParams];
    NSString *path = sdkParams.foregroundRenderResourcePath;
    [self p_hideView];
    if (ACC_isEmptyString(path)) {
        return;
    }
    let frame = self.cameraService.cameraPreviewView.frame;
    let handler = [self.cameraService.effect getEffectHandle];
    
    BEFViewInitParam *initParam = [[BEFViewInitParam alloc] init];
    initParam.effectHandle = handler;
    initParam.renderSize = sdkParams.foregroundRenderSize;
    NSValue *viewFrame = nil;
    if (viewFrame != nil) {
        initParam.frame = [viewFrame CGRectValue];
    } else {
        initParam.frame = frame;
    }
    initParam.fitMode = sdkParams.foregroundRenderFitMode;
    initParam.fps = sdkParams.foregroundRenderFPS;
    initParam.bizId = @"shootpage";
    
    BEFView *view = [[BEFView alloc] initWithParam:initParam];
    self.view = view;
    [self.viewContainer.preview addSubview:view];
    [view loadStickerFullPath:path];
    [view addMessageDelegate:self];
    [self p_addObserverForView:view];
}

- (void)p_hideView
{
    if (self.view) {
        [self.view onPause];
        [self.view removeMessageDelegate:self];
        [self.view removeFromSuperview];
        self.view = nil;
    }
}

#pragma mark - BEFViewDelegate

- (BOOL)msgProc:(unsigned int)msgid arg1:(long)arg1 arg2:(long)arg2 arg3:(const char *)arg3
{
    IESMMEffectMessage *msg = [[IESMMEffectMessage alloc] init];
    msg.type = msgid;
    msg.arg1 = arg1;
    msg.arg2 = arg2;
    if (arg3 != NULL) {
        msg.arg3 = [NSString stringWithUTF8String:arg3];
    }
    [self.cameraService.message sendMessageToEffect:msg];
    return YES;
}

- (ACCPropViewModel *)propViewModel
{
    return [self getViewModel:[ACCPropViewModel class]];
}

@end
