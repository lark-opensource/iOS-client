//
//  ACCFriendsServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/11/5.
//

#import <UIKit/UIKit.h>

@class IESEffectModel;
@protocol ACCUserModelProtocol;
@protocol ACCPrivacyPermissionDecouplingManagerProtocol;
@protocol ACCPublishPrivacySecurityManagerProtocol;

typedef void(^ACCFriendExclusionListBlock)(NSArray <id<ACCUserModelProtocol>> *exclusionList, NSArray<NSString *> * _Nullable exclusionSecUidList, NSInteger totalCount, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerShowcaseEntranceView <NSObject>

- (void)updateWithSticker:(IESEffectModel *)sticker creationID:(NSString *)creationID;

@end

typedef UIView<ACCStickerShowcaseEntranceView> ACCStickerShowcaseEntranceView;

typedef NS_ENUM(NSInteger, ACCSinglePhotoCanvasLayoutType) {
    ACCSinglePhotoCanvasLayoutTypeDefault = 0,
    ACCSinglePhotoCanvasLayoutTypeAuto = 1,
    ACCSinglePhotoCanvasLayoutTypePictureInPicture = 2,
};

typedef struct {
    BOOL isCanvasEnabled;
    ACCSinglePhotoCanvasLayoutType layoutType;
    BOOL isCanvasInteractionGuideEnabled;
    BOOL isGradientBackgroundEnabled;
    double maximumPhotoImportSizeMultiple;
    BOOL isInteractionEnabled;
    CGSize exportSize;
    NSTimeInterval minimumVideoDuration;
    NSTimeInterval maximumVideoDuration;
} ACCSinglePhotoOptimizationABTesting;

@protocol ACCFriendsServiceProtocol <NSObject>

- (ACCStickerShowcaseEntranceView *)createStickerShowcaseEntranceView;

- (BOOL)isStickerShowcaseEntranceEnabled;

- (BOOL)isTextStickerShortcutEnabled;

- (ACCSinglePhotoOptimizationABTesting)singlePhotoOptimizationABTesting;

- (CGFloat)enterQuickRecordInFamiliarDateDiff;

- (BOOL)shouldShowCloseButtonOnMusicButton;

- (BOOL)shouldSelectMusicAutomaticallyForTextMode;

- (BOOL)shouldSelectMusicAutomaticallyForSinglePhoto;

- (BOOL)shouldUseMVMusicForSinglePhoto;

- (void)recordPreviousEnterFrom:(NSString *)enterFrom;

- (NSInteger)minimumDayIntervalToAddAnimatedDateStickerAutomatically;

- (void)refreshPublishExclusionListWithAwemeID:(NSString * _Nullable)awemeID
                                      isDigest:(BOOL)isDigest
                                    completion:(ACCFriendExclusionListBlock)completion;

- (Class<ACCPrivacyPermissionDecouplingManagerProtocol>)AWEPrivacyPermissionDecouplingManagerClass;
- (id<ACCPublishPrivacySecurityManagerProtocol>)publishPrivacySecurityManager;
@end

NS_ASSUME_NONNULL_END
