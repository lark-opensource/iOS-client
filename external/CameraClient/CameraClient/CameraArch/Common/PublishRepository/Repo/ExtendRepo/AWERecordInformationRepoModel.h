//
//  AWERecordInformationRepoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 马超 on 2021/4/23.
//

#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "AWEVideoFragmentInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWERecordInformationRepoModel : ACCRecordInformationRepoModel

@property (nonatomic, strong) AWEPictureToVideoInfo *pictureToVideoInfo;
@property (nonatomic, assign) BOOL isCommerceDataInToolsLine;

- (BOOL)shouldForbidCommerce;
- (BOOL)shouldForbidCommerce:(NSMutableArray * _Nullable)log; // 额外输出日志

- (BOOL)isCommerceStickerOrMV;

- (BOOL)hasStickers;

#pragma mark - Compatible
// 兼容草稿迁移 & 兼容安全改造之前的草稿；
- (void)updateFragmentInfo:(NSArray<__kindof id<ACCVideoFragmentInfoProtocol>> *)fragmentInfo;
- (void)updateVideoFragmentInfo;

@end

@interface AWEVideoPublishViewModel (AWERepoRecordInformation)

@property (nonatomic, strong, readonly) AWERecordInformationRepoModel *repoRecordInfo;

- (nullable NSString *)effectTrackStringWithFilter:(BOOL(^ _Nullable)(ACCEffectTrackParams *param))filter;
@end

NS_ASSUME_NONNULL_END
