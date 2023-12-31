//
//  ACCRecordCommerceEnterComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/8/5.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCRecordCommerceEnterComponent.h"
#import <CameraClient/ACCIronManServiceProtocol.h>
#import "ACCCommerceServiceProtocol.h"
#import <CameraClient/ACCRNEventProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCRecordCommerceEnterViewModel.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import "ACCSpeedControlViewModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import "ACCKaraokeService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>

@interface ACCRecordCommerceEnterComponent ()<ACCRecorderViewContainerItemsHideShowObserver, ACCKaraokeServiceSubscriber>

//商业化转换挂件入口埋点
@property (nonatomic, weak)   id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@property (nonatomic, strong) NSString *lastCommerceEnterEffectID;
@property (nonatomic, strong) ACCAnimatedButton *commerceEnterButton; // 商业化闭环能力入口Btn
@property (nonatomic, strong) UILabel *commerceEnterLabel;
@property (nonatomic, assign) BOOL commerceEnterShowOfPause;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) ACCRecordCommerceEnterViewModel *viewModel;

@end

@implementation ACCRecordCommerceEnterComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - ACCRecordCommerceEnterComponentProtocol

- (void)trackCommerceEnterPendentWithForce:(BOOL)force
{
    if ([self.lastCommerceEnterEffectID isEqualToString:self.propViewModel.currentSticker.effectIdentifier] && !force) {
        return;
    }
    NSString *effectID = self.propViewModel.currentSticker ? self.propViewModel.currentSticker.effectIdentifier : self.viewModel.inputData.localSticker.effectIdentifier;
    self.lastCommerceEnterEffectID = effectID;
    [ACCTracker() trackEvent:@"show_transform_link"
                                     params:@{@"shoot_way": self.viewModel.inputData.publishModel.repoTrack.referString ?: @"",
                                              @"carrier_type": @"video_shoot_page",
                                              @"prop_id": effectID ?: @""
                                     }
                            needStagingFlag:NO];
}

#pragma mark - ACCComponentProtocol

- (void)loadComponentView
{
    self.commerceEnterButton.hidden = YES;
    [self.viewContainer.layoutManager addSubview:self.commerceEnterButton viewType:ACCViewTypeCommerceEnter];
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    [self addObservers];
}

- (void)componentWillAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self.commerceEnterButton addSubview:self.commerceEnterLabel];
        ACCMasMaker(self.commerceEnterLabel, {
            make.left.equalTo(self.commerceEnterButton).offset(12);
            make.right.equalTo(self.commerceEnterButton).offset(-24.0f);
            make.centerY.equalTo(self.commerceEnterButton);
        });

        UIImageView *arrowImage = [[UIImageView alloc] init];
        [arrowImage setImage:ACCResourceImage(@"icBuynow")];
        [self.commerceEnterButton addSubview:arrowImage];
        ACCMasMaker(arrowImage, {
            make.left.equalTo(self.commerceEnterLabel.mas_right).offset(2.0);
            make.centerY.equalTo(self.commerceEnterButton);
        });

        [self.commerceEnterButton addTarget:self action:@selector(clickCommerceEnterAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {} @finally {}
    
    let ironman = IESAutoInline(ACCBaseServiceProvider(), ACCIronManServiceProtocol);
    if (([ironman ironManPublishStatus] != ACCIronManPublishStatusPublish)) {
        [ironman sendIronManMessageAtPage:ACCIronManPageRecord];
    }
}

#pragma mark - KVO

- (void)addObservers
{
    @weakify(self);
    [[NSNotificationCenter defaultCenter] addObserverForName:[IESAutoInline(self.serviceProvider, ACCRNEventProtocol) RNEventBroadcasterNotification] object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);
        NSString *eventName = note.userInfo[@"eventName"];
        if ([eventName isEqualToString:@"good_choose_cancel"]) {
            [self.controller.root dismissViewControllerAnimated:YES completion:^{}];
        }
    }];
    [[self propViewModel].propSelectionSignal.deliverOnMainThread subscribeNext:^(ACCPropSelection * _Nullable x) {
        @strongify(self);
        if (x.effect == nil) {
            self.lastCommerceEnterEffectID = nil;
        }
        [self updateCommerceEnterContentWithText:x.effect.commerceBuyText];
        [self updateCommerceEnterVisibilityWithAnimated:NO];
    }];
    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self updateCommerceEnterVisibilityWithAnimated:YES];
    }];
    
    [RACObserve([self speedControlViewModel], speedControlButtonSelected).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self updateCommerceEnterContentWithText:self.propViewModel.currentSticker.commerceBuyText];
        [self updateCommerceEnterVisibilityWithAnimated:NO];
    }];
    [self.viewContainer addObserver:self];
    [self.karaokeService addSubscriber:self];
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateCommerceEnterContentWithText:self.propViewModel.currentSticker.commerceBuyText];
    [self updateCommerceEnterVisibilityWithAnimated:animated];
}

- (void)updateCommerceEnterContentWithText:(NSString *)text
{
    self.commerceEnterLabel.text = text;
    [self.commerceEnterLabel sizeToFit];
    [self.viewContainer.layoutManager updateCommerceEnterButton];
}

- (void)updateCommerceEnterVisibilityWithAnimated:(BOOL)animated
{
    BOOL isKaraokeAudioMode = self.karaokeService.inKaraokeRecordPage && self.karaokeService.recordMode == ACCKaraokeRecordModeAudio;
    BOOL isRecording = self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording;
    
    BOOL hidden = self.viewContainer.itemsShouldHide || isKaraokeAudioMode || isRecording || self.speedControlViewModel.speedControlButtonSelected || ![self.propViewModel.currentSticker hasCommerceEnter];
    
    if (!hidden) {
        [self trackCommerceEnterPendentWithForce:NO];
    }
    
    if (animated) {
        if (hidden) {
            [self.commerceEnterButton acc_fadeHidden];
        } else {
            [self.commerceEnterButton acc_fadeShow];
        }
    } else {
        self.commerceEnterButton.hidden = hidden;
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service recordModeDidChangeFrom:(ACCKaraokeRecordMode)prevMode to:(ACCKaraokeRecordMode)mode
{
    [self updateCommerceEnterVisibilityWithAnimated:NO];
}

#pragma mark - 试用贴纸入口

- (void)clickCommerceEnterAction:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    NSDictionary *params = @{ @"shoot_way": self.viewModel.inputData.publishModel.repoTrack.referString ? : @"",
                              @"carrier_type": @"video_shoot_page",
                              @"prop_id": self.propViewModel.currentSticker.effectIdentifier ? : @"" };
    [ACCTracker() trackEvent:@"click_transform_link"
                      params:params
             needStagingFlag:NO];

    [IESAutoInline(self.serviceProvider, ACCCommerceServiceProtocol) runTasksWithContext:^(ACCAdTaskContext *_Nonnull context) {
        context.openURL = self.propViewModel.currentSticker.commerceOpenURL;
        context.webURL = [self p_addTrackToURL:self.propViewModel.currentSticker.commerceWebURL withParams:@{ @"_enter_from": @"commerce_sticker_button", @"_extra_query": [self p_stringByAddingPercentEscapes:[params acc_dictionaryToJson]] }];
    } runTasks:@[@(ACCAdTaskTypeInAppOpenURL), @(ACCAdTaskTypeOpenOtherApp), @(ACCAdTaskTypeLandingPage)]];
}

#pragma mark - getter & setter

- (ACCAnimatedButton *)commerceEnterButton
{
    if (!_commerceEnterButton) {
        _commerceEnterButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        _commerceEnterButton.backgroundColor = ACCResourceColor(ACCUIColorSDTertiary);
        
        _commerceEnterButton.layer.cornerRadius = 2.0f;
    }
    return _commerceEnterButton;
}

- (UILabel *)commerceEnterLabel
{
    if (!_commerceEnterLabel) {
        _commerceEnterLabel = [[UILabel alloc] init];
        _commerceEnterLabel.font = [ACCFont() acc_boldSystemFontOfSize:14.0f];
        _commerceEnterLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
    }
    return _commerceEnterLabel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (ACCRecordCommerceEnterViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCRecordCommerceEnterViewModel.class];
    }
    return _viewModel;
}

- (ACCSpeedControlViewModel *)speedControlViewModel
{
    ACCSpeedControlViewModel *viewModel = [self getViewModel:ACCSpeedControlViewModel.class];
    return viewModel;
}

- (NSString *)p_addTrackToURL:(NSString *)url withParams:(NSDictionary *)params
{
    NSMutableArray<NSString *> *suffix = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
            [suffix addObject:[NSString stringWithFormat:@"%@=%@",
                               [self p_stringByAddingPercentEscapes:(NSString *)key],
                               [self p_stringByAddingPercentEscapes:(NSString *)obj]]];
    }];
    NSString *suffixString = [suffix componentsJoinedByString:@"&"];
    if ([url rangeOfString:@"?"].location != NSNotFound) {
        return [NSString stringWithFormat:@"%@&%@", url, suffixString];
    }
    return [NSString stringWithFormat:@"%@?%@", url, suffixString];
}

- (NSString *)p_stringByAddingPercentEscapes:(NSString *)originalString
{
    static NSMutableCharacterSet *allowSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allowSet = [NSMutableCharacterSet characterSetWithCharactersInString:@""];
        [allowSet formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [allowSet removeCharactersInString:@":!*();@/&?+$,='"];
    });
    return [originalString stringByAddingPercentEncodingWithAllowedCharacters:allowSet];
}

@end
