//
//  ACCAlbumInputData.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/16.
//

#import "ACCAlbumInputData.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CameraClient/ACCCutSameWorksManagerProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

const NSInteger MaxAssetCountForAIClipMode = 35;
const NSInteger ACCAlbumSingleVideoLimitTime = 3600;

const static CGFloat    kAlbumSelectedAssetsViewHeight = 88.0f;
const static CGFloat    kAlbumNavigationViewHeight = 54.f;
const static CGFloat    kAlbumBottomViewHeight = 52.0f;
const static CGFloat    kAlbumPreviewBottomViewHeight() { return 52.0f + ACC_IPHONE_X_BOTTOM_OFFSET;}

@implementation ACCAlbumInputData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scrollToBottom = YES;
        _ascendingOrder = YES;
        _enableTabView = YES;
        _defaultTabIdentifier = CAKAlbumTabIdentifierAll;
        _maxAssetsSelectionCount = MaxAssetCountForAIClipMode;
        _minAssetsSelectionCount = 1;
        _horizontalInset = 0.0f;
        _columnNumber = 4;
        _checkMarkSelectedStyle = NO;
        _aspectRatio = CGSizeZero;
        _heightForNavigationView = kAlbumNavigationViewHeight;
        _enableNavigationView = YES;
        _heightForBottomView = kAlbumBottomViewHeight;
        _heightForPreviewBottomView = kAlbumPreviewBottomViewHeight();
        _enableBottomView = YES;
        _heightForSelectedAssetsView = kAlbumSelectedAssetsViewHeight;
        _enableSelectedAssetsView = YES;
        _enableSelectedAssetsViewForPreviewPage = YES;
        _shouldHideSelectedAssetsViewWhenNotSelectForPreviewPage = YES;
        _shouldHideSelectedAssetsViewWhenNotSelect = YES;
        _shouldHideBottomViewWhenNotSelect = NO;
        _enablePreview = YES;
        _enableMultiSelect = YES;
        _addAssetInOrder = NO;
        _enableMixedUpload = YES;
        _enableVideoAssetsTab = YES;
        _enablePhotoAssetsTab = YES;
        _enableMixedAssetsTab = YES;
        _enableSyncInitialSelectedAssets = NO;
        _enableHorizontalAssetBlackEdge = YES;
        _shouldDismissPreviewPageWhenNext = NO;
        _enableiOS14AlbumAuthorizationGuide = YES;
        _shouldShowLocationTag = NO;
        _enableDragToMoveForSelectedAssetsView = YES;
        _enableDragToMoveForSelectedAssetsViewInPreviewPage = YES;
        _withoutCountLimitation = NO;
        _albumId = nil;
        _notificationBlock = nil;
        _availableStorage = nil;
    }
    return self;
}

#pragma mark - Setter

- (void)setCutSameTemplateModel:(id<ACCMVTemplateModelProtocol>)cutSameTemplateModel
{
    _cutSameTemplateModel = cutSameTemplateModel;
    
    if (cutSameTemplateModel) {
        _maxAssetsSelectionCount = cutSameTemplateModel.fragmentCount;
        _minAssetsSelectionCount = _maxAssetsSelectionCount;
        let cutSameWorksManager = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameWorksManagerProtocol);
        cutSameWorksManager.currrentTemplate = cutSameTemplateModel;
    }
}

- (void)setSingleFragment:(id<ACCCutSameFragmentModelProtocol>)singleFragment
{
    _singleFragment = singleFragment;
}

#pragma mark - Getter

- (CGFloat)videoSelectableMinSeconds
{
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if ([self isDuet]) {
        return config.duetVideoMinSeconds;
    }
    return config.videoMinSeconds;
}

- (CGFloat)videoSelectableMaxSeconds
{
    if ([self isDuet]) {
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        return config.duetVideoMaxSeconds;
    }
    
    if (ACCConfigBool(kConfigBool_enable_new_clips)) {
        return ACCAlbumSingleVideoLimitTime;
    }
    if (self.isStory) {
        return MAXFLOAT;
    }
    
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    return config.videoSelectableMaxSeconds;
}

- (BOOL)enableMutilPhotosToAIVideo
{
    return ACCConfigBool(kConfigBool_enable_multi_photos_to_ai_video);
}

- (BOOL)isDefault
{
    return self.vcType == ACCAlbumVCTypeForUpload;
}

- (BOOL)isStory
{
    return self.vcType == ACCAlbumVCTypeForStory;
}

- (BOOL)isMV
{
    return self.vcType == ACCAlbumVCTypeForMV;
}

- (BOOL)isDuet
{
    return self.vcType == ACCAlbumVCTypeForDuet;
}

- (BOOL)isPixaloop
{
    return self.vcType == ACCAlbumVCTypeForPixaloop;
}

- (BOOL)isMultiAssetsPixaloop
{
    return self.vcType == ACCAlbumVCTypeForMultiAssetsPixaloop;
}

- (BOOL)isAIClipAppend
{
    return self.vcType == ACCAlbumVCTypeForAIVideoClip;
}

- (BOOL)isVideoBG
{
    return self.vcType == ACCAlbumVCTypeForVideoBG;
}

- (BOOL)isCutSame
{
    return self.vcType == ACCAlbumVCTypeForCutSame;
}

- (BOOL)isCutSameChangeMaterial
{
    return self.vcType == ACCAlbumVCTypeForCutSameChangeMaterial;
}

- (BOOL)isPhotoToVideo
{
    return self.vcType == ACCAlbumVCTypeForPhotoToVideo;
}

- (BOOL)isFirstCreative {
    return self.vcType == ACCAlbumVCTypeForFirstCreative;
}

- (BOOL)isKaraokeAudioBG
{
    return self.vcType == ACCAlbumVCTypeForKaraokeAudioBG;
}

- (BOOL)isCloudAlbum
{
    return self.vcType == ACCCloudAlbumVCTypeForPrivatePage;
}

- (BOOL)isWishBG
{
    return self.vcType == ACCAlbumVCTypeForWish;
}

- (BOOL)isMaterialRepeatSelect {
    BOOL isRepeatSelect = self.vcType == ACCAlbumVCTypeForMV || self.vcType == ACCAlbumVCTypeForCutSame;
    return isRepeatSelect;
}

- (NSString *)shootWay
{
    if (self.fromShareExtension) {
        return self.originUploadPublishModel.repoTrack.referString = @"system_upload";
    } else if (self.originUploadPublishModel.repoTrack.referString) {
        return self.originUploadPublishModel.repoTrack.referString;
    } else {
        return self.fromStickPointAnchor ? @"upload_anchor" : @"direct_shoot";
    }
}

- (NSUInteger)maxSelectionCount
{
    if (self.vcType == ACCAlbumVCTypeForMV ||
        self.vcType == ACCAlbumVCTypeForCutSame ||
        self.vcType == ACCAlbumVCTypeForCutSameChangeMaterial ||
        self.vcType == ACCAlbumVCTypeForMultiAssetsPixaloop ||
        self.vcType == ACCAlbumVCTypeForKaraokeAudioBG ||
        self.vcType == ACCAlbumVCTypeForDuet ||
        self.vcType == ACCAlbumVCTypeForWish) {
        return self.maxAssetsSelectionCount;
    }
    
    return MaxAssetCountForAIClipMode - self.initialSelectedPictureCount;
}

@end
