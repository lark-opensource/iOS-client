//
//  ACCRecorderLiveStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/10.
//

#import "ACCRecorderLiveStickerComponent.h"
#import "ACCLiveStickerHandler.h"
#import "AWERepoStickerModel.h"
#import "AWEInteractionLiveStickerModel.h"
#import "ACCRecorderStickerServiceProtocol.h"
#import "ACCRecordAuthService.h"
#import "AWERepoDraftModel.h"
#import "AWERepoUploadInfomationModel.h"
#import "AWEVideoPublishResponseModel.h"

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCRecordAuthDefine.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitArch/ACCRecordMode.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "AWERepoContextModel.h"
#import "AWERepoTrackModel.h"

@interface ACCRecorderLiveStickerComponent()<ACCLiveStickerDataProvider, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, weak) id<ACCRecorderStickerServiceProtocol> stickerService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordAuthService> authService;
@property (nonatomic, strong) ACCLiveStickerHandler *liveHandler;

@property (nonatomic, assign) BOOL autoAdded;

@end

@implementation ACCRecorderLiveStickerComponent

IESAutoInject(self.serviceProvider, stickerService, ACCRecorderStickerServiceProtocol)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, authService, ACCRecordAuthService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.stickerService registerStickerHandler:self.liveHandler];
    [self.switchModeService addSubscriber:self];
}

- (void)componentDidAppear
{
    // 代表来自直播页
    if (!self.autoAdded && [[self.repository.repoUploadInfo.extraDict acc_stringValueForKey:@"shoot_enter_from"] isEqualToString:@"live_page"] && !self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
        ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
        if ((authType & ACCRecordAuthComponentCameraAuthed) && (authType & ACCRecordAuthComponentMicAuthed)) {
            [self autoAddLiveSticker:self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp];
        } else {
            @weakify(self);
            [[self.authService.passCheckAuthSignal takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
                @strongify(self);
                ACCRecordAuthComponentAuthType authType = [ACCDeviceAuth currentAuthType];
                if ((authType & ACCRecordAuthComponentCameraAuthed) && (authType & ACCRecordAuthComponentMicAuthed)) {
                    [self autoAddLiveSticker:self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp];
                }
            }];
        }
        self.autoAdded = YES;
    }
}

- (void)autoAddLiveSticker:(BOOL)fromRecover
{
    self.liveHandler.stickerContainerView = self.stickerService.stickerContainerView;
    
    AWEInteractionLiveStickerModel *liveModel = [[AWEInteractionLiveStickerModel alloc] init];
    liveModel.liveInfo = [[AWEInteractionLiveStickerInfoModel alloc] init];
    [self.liveHandler addLiveSticker:liveModel fromRecover:fromRecover fromAuto:YES];
}

- (ACCLiveStickerHandler *)liveHandler
{
    if (!_liveHandler) {
        _liveHandler = [[ACCLiveStickerHandler alloc] init];
        _liveHandler.dataProvider = self;
    }
    return _liveHandler;
}

#pragma mark - ACCLiveStickerDataProvider
- (NSValue *)gestureInvalidFrameValue
{
    return self.repository.repoSticker.gestureInvalidFrameValue;
}

- (BOOL)hasLived
{
    return YES;
}

- (BOOL)isKaraokeMode
{
    return self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
}

- (NSString *)referString
{
    return self.repository.repoTrack.referString;
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.liveHandler changeStickerStatus:(mode.modeId != ACCRecordModeKaraoke)];
}

@end
