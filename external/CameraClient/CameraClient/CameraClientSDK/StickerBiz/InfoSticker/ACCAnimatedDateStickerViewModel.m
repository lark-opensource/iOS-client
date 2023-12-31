//
//  ACCAnimatedDateStickerController.m
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2021/3/18.
//

#import "ACCAnimatedDateStickerViewModel.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import "ACCDraftProtocol.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@interface ACCAnimatedDateStickerViewModel ()

@property (nonatomic, assign) BOOL triedFetchingBefore;

@end

@implementation ACCAnimatedDateStickerViewModel

- (void)fetchStickerWithCompletion:(void (^)(IESEffectModel * _Nullable, NSString * _Nullable, NSString * _Nullable, NSError * _Nullable))completion
{
    self.triedFetchingBefore = YES;
    if (![self shouldAddAnimatedDateSticker]) {
        if (completion) {
            completion(nil, nil, nil, [NSError errorWithDomain:@"ACCStickerErrorDomain" code:1 userInfo:nil]);
        }
        return;
    }
    
    RACSignal *fetchStcker = [self fetchEffectWithEffectID:@"1063065"];
    RACSignal *fetchAnimation = [self fetchEffectWithEffectID:@"1063067"];
    [[RACSignal combineLatest:@[fetchStcker, fetchAnimation]] subscribeNext:^(RACTuple * _Nullable x) {
        RACTwoTuple<IESEffectModel *, NSString *> *fetchStickerResult = x.first;
        RACTwoTuple<IESEffectModel *, NSString *> *fetchAnimationResult = x.second;
        if (completion) {
            completion(fetchStickerResult.first, fetchStickerResult.second, fetchAnimationResult.second, nil);
        }
    } error:^(NSError * _Nullable error) {
        if (completion) {
            completion(nil, nil, nil, error);
        }
    }];
}

- (RACSignal<RACTwoTuple<IESEffectModel *, NSString *> *> *)fetchEffectWithEffectID:(NSString *)effectID
{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        [AWEColorFilterDataManager loadEffectWithID:effectID completion:^(IESEffectModel *sticker) {
            if (!sticker) {
                [subscriber sendError:[NSError errorWithDomain:@"ACCStickerErrorDomain" code:1 userInfo:nil]];
                return;
            }
            [ACCDraft() saveInfoStickerPath:sticker.filePath draftID:self.repository.repoDraft.taskID completion:^(NSError *draftError, NSString *draftStickerPath) {
                if (draftError || draftStickerPath.length == 0) {
                    AWELogToolError(AWELogToolTagEdit, @"save info sticker to draft failed: %@", draftError);
                    [subscriber sendError:draftError];
                    return;
                }
                [subscriber sendNext:[RACTwoTuple tupleWithObjectsFromArray:@[sticker, draftStickerPath]]];
                [subscriber sendCompleted];
            }];
        }];
        return nil;
    }];
}

- (BOOL)shouldAddAnimatedDateSticker
{
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeA) {
        return NO;
    }
    if (!self.repository.repoSticker.assetCreationDate) {
        return NO;
    }
    
    BOOL isCapturedSinglePhoto = self.repository.repoContext.videoSource == AWEVideoSourceCapture
    && (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo || self.repository.repoContext.videoType == AWEVideoTypeQuickStoryPicture);
    
    BOOL isImportedSinglePhoto = self.repository.repoContext.videoSource == AWEVideoSourceAlbum
    && self.repository.repoUploadInfo.originUploadPhotoCount.integerValue == 1
    && self.repository.repoUploadInfo.originUploadVideoClipCount.integerValue == 0;

    if (!isCapturedSinglePhoto && !isImportedSinglePhoto) {
        return NO;
    }
    
    NSInteger minimumDaysInterval = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) minimumDayIntervalToAddAnimatedDateStickerAutomatically];
    if (minimumDaysInterval <= 0) {
        return YES;
    }
    
    NSDate *assetCreationDate = self.repository.repoSticker.assetCreationDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = -minimumDaysInterval;
    NSDate *theDayBeforeDaysInterval = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    BOOL earlier = [calendar compareDate:assetCreationDate toDate:theDayBeforeDaysInterval toUnitGranularity:NSCalendarUnitDay] != NSOrderedDescending;
    return earlier;
}

- (NSDate *)usedDate
{
    return self.repository.repoSticker.assetCreationDate ?: [NSDate date];
}

- (ACCAnimatedDateStickerDateFormattingStyle)dateFormattingStyle
{
    ACCAnimatedDateStickerDateFormattingStyle style = ACCAnimatedDateStickerDateFormattingStyleHourMinute;
    if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum) {
        NSDate *assetCreationDate = self.repository.repoSticker.assetCreationDate ?: [NSDate date];
        NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:assetCreationDate toDate:[NSDate date] options:0];
        if (dateComponents.day > 0) {
            style = ACCAnimatedDateStickerDateFormattingStyleYearMonthDay;
        }
    }
    return style;
}

@end
