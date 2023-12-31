//
//  ACCAlbumInputData.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEAssetModel.h>
#import "ACCPhotoAlbumDefine.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCPhotoAlbumDefine.h"

#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CreationKitArch/ACCCutSameFragmentModelProtocol.h>
#import <CameraClient/ACCWorksPreviewViewControllerProtocol.h>

FOUNDATION_EXPORT const NSInteger MaxAssetCountForAIClipMode;
FOUNDATION_EXPORT const NSInteger ACCAlbumSingleVideoLimitTime;

@protocol CAKAlbumNavigationViewProtocol, ACCSelectedAssetsBottomViewProtocol, ACCSelectedAssetsViewProtocol, CAKAlbumListViewControllerProtocol, CAKAlbumPreviewPageBottomViewProtocol;

typedef NS_OPTIONS(NSInteger, ACCAlbumTagFlag) {
    ACCAlbumTagFlagSinglePhoto = 1,
    ACCAlbumTagFlagMultiPhoto = 1 << 1,
    ACCAlbumTagFlagSingleVideo = 1 << 2,
    ACCAlbumTagFlagMultiVideo = 1 << 3,
};

@interface ACCAlbumInputData : NSObject

@property (nonatomic, copy, nullable) ACCAlbumDismissBlock dismissBlock;
@property (nonatomic, copy, nullable) ACCAlbumShouldStartClipBlock shouldStartClipBlock;
@property (nonatomic, copy, nullable) ACCAlbumSelectPhotoCompletion selectPhotoCompletion;
@property (nonatomic, copy, nullable) ACCAlbumSelectAssetsCompletion selectAssetsCompletion;
@property (nonatomic, copy, nullable) ACCAlbumSelectToScanCompletion selectToScanCompletion;

@property (nonatomic, assign) BOOL scrollToBottom;
@property (nonatomic, assign) BOOL ascendingOrder;
/** 是否是从拍摄页-照片或者长按加号入口进入的 */
@property (nonatomic, assign) BOOL isFromShootingPageOrPlusButton;

@property (nonatomic, assign) BOOL enableTabView;
@property (nonatomic, assign) BOOL fromStickPointAnchor;

@property (nonatomic, assign) NSString *defaultTabIdentifier;
@property (nonatomic, assign) ACCAlbumVCType vcType;

// photo vc
@property (nonatomic, strong) IESEffectModel *templateEffectModel;

// ACCSelectAlbumAssetsInputData
@property (nonatomic, strong) AWEVideoPublishViewModel *originUploadPublishModel;
@property (nonatomic, assign) NSUInteger maxAssetsSelectionCount;
@property (nonatomic, assign) NSUInteger minAssetsSelectionCount;
@property (nonatomic, copy) NSArray<AWEAssetModel *> *initialSelectedAssetModelArray;
@property (nonatomic, assign) BOOL enableSyncInitialSelectedAssets;

/// select count
@property (nonatomic, assign) BOOL withoutCountLimitation;
@property (nonatomic, assign) NSUInteger initialSelectedPictureCount; // Number of initial selected resources when supporting append selection

/// cut same
@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> cutSameTemplateModel;
@property (nonatomic, strong) id<ACCCutSameFragmentModelProtocol> singleFragment;
@property (nonatomic, copy) ACCWorksPreviewViewControllerChangeMaterialCallback changeMaterialCallback;

/// track info
@property (nonatomic, copy) NSDictionary *trackExtraDic;

@property (nonatomic, copy) NSString *enterFrom;
@property (nonatomic, copy) NSString *enterMethod;
@property (nonatomic, copy) NSString *groupId;
@property (nonatomic, copy) NSString *musicId;
@property (nonatomic, copy) NSString *ugcPathRefer;
@property (nonatomic, assign) BOOL fromShareExtension;
@property (nonatomic, copy, nullable) NSString *matchedCityName;


/// next button prefix string
@property (nonatomic, strong) NSString *prefixTitle;

@property (nonatomic, weak, readonly) NSArray<UIViewController *> *listViewControllers;


//ACCAlbumViewUIConfig
@property (nonatomic, assign) CGFloat horizontalInset;
@property (nonatomic, assign) NSInteger columnNumber;
@property (nonatomic, assign) BOOL checkMarkSelectedStyle;
@property (nonatomic, assign) CGSize aspectRatio;

@property (nonatomic, assign) CGFloat heightForNavigationView;
@property (nonatomic, strong) UIView<CAKAlbumNavigationViewProtocol> *customNavigationView;
@property (nonatomic, assign) BOOL enableNavigationView;
@property (nonatomic, assign) CGFloat heightForBottomView;
@property (nonatomic, strong) UIView<ACCSelectedAssetsBottomViewProtocol> *customBottomView;
@property (nonatomic, assign) BOOL enableBottomView;
@property (nonatomic, assign) CGFloat heightForSelectedAssetsView;
@property (nonatomic, strong) UIView<ACCSelectedAssetsViewProtocol> *customSelectedAssetsView;

@property (nonatomic, assign) BOOL enableBottomViewForPreviewPage;
@property (nonatomic, assign) CGFloat heightForPreviewBottomView;
@property (nonatomic, strong) UIView<CAKAlbumPreviewPageBottomViewProtocol> *customBottomViewForPreviewPage;

/// enable to show the selected assetes view for multi-select page
@property (nonatomic, assign) BOOL enableSelectedAssetsView;
/// enable drag to move asset in selected assetes view for multi-select page
@property (nonatomic, assign) BOOL enableDragToMoveForSelectedAssetsView;
/// enable to show the selected assetes view for preview page
@property (nonatomic, assign) BOOL enableSelectedAssetsViewForPreviewPage;
/// enable drag to move asset in selected assetes view for preview page
@property (nonatomic, assign) BOOL enableDragToMoveForSelectedAssetsViewInPreviewPage;

@property (nonatomic, strong, nullable) UIView<ACCSelectedAssetsViewProtocol> *customSelectedAssetsViewForPreviewPage;
@property (nonatomic, assign) BOOL enableHorizontalAssetBlackEdge;
@property (nonatomic, assign) BOOL shouldHideSelectedAssetsViewWhenNotSelectForPreviewPage;

@property (nonatomic, assign) BOOL shouldHideSelectedAssetsViewWhenNotSelect;
@property (nonatomic, assign) BOOL shouldHideBottomViewWhenNotSelect;
@property (nonatomic, assign) BOOL enablePreview;
@property (nonatomic, assign) BOOL enableMultiSelect;
@property (nonatomic, assign) BOOL enableSwitchMultiSelect; // 开启切换单选/多选，default NO
@property (nonatomic, assign) BOOL previewNextNeverDisabled; // 预览页下一步始终可点击，default NO
@property (nonatomic, assign) BOOL addAssetInOrder;
@property (nonatomic, assign) BOOL enableMixedUpload;
@property (nonatomic, assign) BOOL shouldShowLocationTag;
@property (nonatomic, strong) NSMutableSet<NSString *> *showCityTagAssetLocalIdentifierSet;

@property (nonatomic, assign) BOOL enableMixedAssetsTab;
@property (nonatomic, assign) BOOL enablePhotoAssetsTab;
@property (nonatomic, assign) BOOL enableVideoAssetsTab;

@property (nonatomic, assign) BOOL enableiOS14AlbumAuthorizationGuide;
@property (nonatomic, assign) BOOL enableAlbumAuthorizationDenyAccessGuide;
@property (nonatomic, assign) BOOL shouldDismissPreviewPageWhenNext;

//ACCAlbumConfigViewModel
@property (nonatomic, assign, readonly) CGFloat videoSelectableMinSeconds;
@property (nonatomic, assign, readonly) CGFloat videoSelectableMaxSeconds;
@property (nonatomic, assign, readonly) BOOL enableMutilPhotosToAIVideo;    // enable upload page add all tab
@property (nonatomic, assign, readonly) BOOL enableMoments;         // enable moments

@property (nonatomic, assign, readonly) BOOL isDefault;
@property (nonatomic, assign, readonly) BOOL isStory;
@property (nonatomic, assign, readonly) BOOL isMV;
@property (nonatomic, assign, readonly) BOOL isDuet;
@property (nonatomic, assign, readonly) BOOL isPixaloop;
@property (nonatomic, assign, readonly) BOOL isMultiAssetsPixaloop;
@property (nonatomic, assign, readonly) BOOL isAIClipAppend;
@property (nonatomic, assign, readonly) BOOL isVideoBG;
@property (nonatomic, assign, readonly) BOOL isCutSame;
@property (nonatomic, assign, readonly) BOOL isCutSameChangeMaterial;
@property (nonatomic, assign, readonly) BOOL isPhotoToVideo;
@property (nonatomic, assign, readonly) BOOL isFirstCreative;
@property (nonatomic, assign, readonly) BOOL isKaraokeAudioBG;
@property (nonatomic, assign, readonly) BOOL isWishBG;
@property (nonatomic, assign, readonly) BOOL isMaterialRepeatSelect;
@property (nonatomic, assign, readonly) BOOL isCloudAlbum;
@property (nonatomic, assign, readonly) BOOL showMomentsTab;
// 云相册
@property (nonatomic, strong, nullable) NSNumber *albumId;
@property (nonatomic, strong, nullable) NSNumber *availableStorage;
@property (nonatomic, copy) void(^notificationBlock)(BOOL success);

@property (nonatomic, assign) ACCAlbumTagFlag tagFlag;
- (NSString *)shootWay;
- (NSUInteger)maxSelectionCount;

@end
