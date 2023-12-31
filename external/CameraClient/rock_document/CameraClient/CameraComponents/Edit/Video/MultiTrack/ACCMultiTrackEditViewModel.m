//
//  ACCMultiTrackEditViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/15.
//

#import "ACCMultiTrackEditViewModel.h"

#import <IESInject/IESInject.h>
#import <CameraClient/ACCNLEUtils.h>
#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/AWERepoContextModel.h>

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

@interface ACCMultiTrackEditViewModel ()

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@end

@implementation ACCMultiTrackEditViewModel

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - life cycle

- (void)dealloc {
    
}

#pragma mark - Public

+ (BOOL)enableMultiTrackWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel {
    BOOL enableNLE = [ACCNLEUtils useNLEWithRepository:publishViewModel];
    BOOL isDuet = publishViewModel.repoDuet.isDuet;
    BOOL isDuetUpload = publishViewModel.repoDuet.isDuetUpload;
    return enableNLE && isDuetUpload && isDuet;
}

- (BOOL)enableMultiTrack { // 使用多轨编辑业务场景
    return [self.class enableMultiTrackWithPublishViewModel:self.repository];
}

- (void)bindViewModel {
    if ([self enableMultiTrack]) {
        [self handleDuetLayoutMultiTrackAndRender];
    }
}

- (void)handleDuetLayoutMultiTrackAndRender { // 合拍布局多轨业务
    // 合拍副轨道兜底配置音量设置为0
    [self.editService.audioEffect setVolumeForVideoSubTrack:0];
}

@end
