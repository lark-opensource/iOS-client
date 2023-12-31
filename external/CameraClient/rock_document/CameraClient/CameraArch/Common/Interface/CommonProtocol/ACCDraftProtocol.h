//
//  ACCDraftProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/14.
//  草稿箱分两步：
//  1.为了拍摄页下沉先解耦；
//  2.未来中台实现草稿方案，外部调用接口，涉及到一次数据迁移；

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/ACCDraftModelProtocol.h>
#import "ACCEditVideoData.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>

@protocol ACCPublishRepository;
@protocol ACCEditServiceProtocol;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCDraftProtocol <NSObject>

#pragma mark - save
- (void)saveDraftWithPublishViewModel:(AWEVideoPublishViewModel *)model
                                video:(ACCEditVideoData *)video
                               backup:(BOOL)backup
                           completion:(void(^ _Nullable)(BOOL success, NSError *error))completion;

- (void)saveDraftWithPublishViewModel:(AWEVideoPublishViewModel *)model
                                video:(ACCEditVideoData *)video
                               backup:(BOOL)backup
                       presaveHandler:(void(^)(id<ACCDraftModelProtocol>))presaveHandler
                           completion:(void(^ _Nullable)(BOOL success, NSError *error))completion;

- (void)trackSaveDraftWithViewModel:(AWEVideoPublishViewModel *)model from:(NSString *)from;

- (void)showSaveDraftToastIfNeededWithViewModel:(AWEVideoPublishViewModel *)model;

- (void)saveInfoStickerPath:(NSString *)filePath draftID:(NSString *)draftID completion:(void(^)(NSError *draftError, NSString *draftStickerPath))completion;

- (void)updateCoverImageWithViewModel:(AWEVideoPublishViewModel *)model
                          editService:(id<ACCEditServiceProtocol>)editService
                           completion:(void(^_Nullable)(NSError *error))completion;

#pragma mark - retrieve
- (id<ACCDraftModelProtocol, ACCPublishRepository>)retrieveWithDraftId:(NSString *)draftId;
- (NSArray<id<ACCDraftModelProtocol, ACCPublishRepository>> *)retrieveDrafts;
- (NSArray<id<ACCDraftModelProtocol, ACCPublishRepository>> *)retrieveEditBackUps;
- (void)retrieveNewestDraftCoverWithCompletion:(void(^)(UIImage *image,NSError *error))completion;

#pragma mark - get/set value
- (void)setCacheDirPathWithID:(NSString *)draftID; // 设置视频缓存路径
- (BOOL)hasPublishBackUp;
- (void)markAllPublishBackupAsDraft;
- (BOOL)hasDraft;
- (NSInteger)draftCount;

#pragma mark - delete
- (void)deleteDraftWithID:(NSString *)draftID;
- (void)clearAllEditBackUps;
- (void)clearAllDraft;

#pragma mark - notification
- (NSString *)draftUpdateNotificationName;
- (NSString *)draftShouldScrollToTopKey;
- (NSString *)draftIDKey;

#pragma mark - HTSVideoData
- (NSDictionary *)readVideoDataFromPath:(NSString *)path error:(NSError *__autoreleasing*)error;

#pragma mark - other

- (BOOL)isOnDraftBoxPage;

@end

FOUNDATION_STATIC_INLINE id<ACCDraftProtocol> ACCDraft() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCDraftProtocol)];
}

NS_ASSUME_NONNULL_END
