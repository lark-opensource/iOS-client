//
//  AWERepoFlowerTrackModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by qy on 2021/11/24.
//

#import "AWERepoFlowerTrackModel.h"
#import <CameraClient/AWERepoTrackModel.h>
#import "ACCFlowerCampaignManagerProtocol.h"
#import "AWERepoContextModel.h"
#import "ACCRepoRedPacketModel.h"

@implementation AWERepoFlowerTrackModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoFlowerTrackModel *model = [[AWERepoFlowerTrackModel alloc] init];
    model.lastFlowerPropChooseMethod = self.lastFlowerPropChooseMethod;
    model.fromFlowerCamera = self.fromFlowerCamera;
    model.isFromShootProp = self.isFromShootProp;
    model.isInRecognition = self.isInRecognition;
    model.schemaEnterMethod = self.schemaEnterMethod;
    return model;
}

#pragma mark - public

- (BOOL)shouldAddFlowerShootParams:(NSDictionary *)infos
{
    ACCFLOActivityStageType stage = [ACCFlowerCampaignManager() getCurrentActivityStage];
    BOOL shouldAdd =  (stage == ACCFLOActivityStageTypeAppointment && [ACCFlowerCampaignManager() currentUserHasBooked]) || (stage > ACCFLOActivityStageTypeAppointment && stage < ACCFLOActivityStageTypeOlympic) || [infos acc_boolValueForKey:@"flower_mode"];
    return shouldAdd;
}

- (NSDictionary *)flowerEventShootExtra
{
    NSMutableDictionary *enterDic = @{}.mutableCopy;
    enterDic[@"params_for_special"] = @"flower";
    return enterDic.copy;
}

- (NSString *)lastChooseMethod
{
    AWERepoTrackModel *trackModel = [self.repository extensionModelOfClass:AWERepoTrackModel.class];
    if ([trackModel.referString isEqualToString:@"sf_2022_activity_camera_task_personal_homepage_entrance"] || [trackModel.referString isEqualToString:@"sf_2022_activity"]) {
        return trackModel.referString;
    }
    return self.lastFlowerPropChooseMethod;
}

- (NSString *)flowerTabName
{
    if (self.isFromShootProp) {
        return @"sf_2022_activity_camera_photo";
    }
    return @"sf_2022_activity_camera";
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_referExtraParams
{
    AWERepoTrackModel *trackModel = [self.repository extensionModelOfClass:AWERepoTrackModel.class];
    
    NSMutableDictionary *extrasDict = @{}.mutableCopy;
    // 春节相机新增
    if (self.fromFlowerCamera) {
        extrasDict[@"tab_name"] = @"sf_2022_activity_camera";
    } else {
        extrasDict[@"tab_name"] = trackModel.tabName;
    }
    
    if (self.fromFlowerCamera && self.isFromShootProp) {
        // 拍照道具路径
        extrasDict[@"tab_name"] = @"sf_2022_activity_camera_photo";
        extrasDict[@"record_mode"] = @"photo";
        extrasDict[@"record_method"] = @"shoot_button";
        extrasDict[@"content_source"] = @"slideshow";
        extrasDict[@"content_type"] = @"shoot";
    } else if (self.fromFlowerCamera && self.isInRecognition) {
        // 物种识别路径
        extrasDict[@"content_type"] = @"reality";
    }
        
    AWERepoContextModel *contextModel = [self.repository extensionModelOfClass:AWERepoContextModel.class];
    ACCRepoRedPacketModel *redPacketModel = [self.repository extensionModelOfClass:ACCRepoRedPacketModel.class];
    
    if (contextModel.flowerMode || [redPacketModel didBindRedpacketInfo]) {
        extrasDict[@"params_for_special"] = @"flower";
    }
    
    return extrasDict.copy;
}

@end

@interface AWEVideoPublishViewModel (RepoFlowerTrack) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoFlowerTrack)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoFlowerTrackModel.class];
    return info;
}

- (AWERepoFlowerTrackModel *)repoFlowerTrack
{
    AWERepoFlowerTrackModel *flowerTrackModel = [self extensionModelOfClass:AWERepoFlowerTrackModel.class];
    NSAssert(flowerTrackModel, @"extension model should not be nil");
    return flowerTrackModel;
}

@end
