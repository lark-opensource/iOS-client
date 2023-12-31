//
//  ACCModuleService.h
//  component-third
//
//  Created by songxiangwu on 2019/7/24.
//  Copyright © 2019 songxiangwu. All rights reserved.
//

#ifndef ACCModuleService_h
#define ACCModuleService_h

#endif /* ACCModuleService_h */

#define ACCRecordModeIdentifier NSInteger

// Don't take the number 0
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeTakePicture;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeLive;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMixHoldTapRecord; // Take a video
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMV;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMixHoldTap15SecondsRecord; // Multi shot - 15s
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMixHoldTapLongVideoRecord; // Multi shot - 60s
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeStory; // Quick shot
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeCombined; // Multi shot
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeText;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMixHoldTap60SecondsRecord;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMixHoldTap3MinutesRecord;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeStoryCombined; // Snapshot with sub modes
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeMiniGame; // Games
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeKaraoke; // Karaoke
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeCreatorPreview; // Effect Studio Preview
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeLivePhoto;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeDuet;
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeTheme; // lite theme mode
FOUNDATION_EXPORT ACCRecordModeIdentifier const ACCRecordModeAudio;

// for server
typedef NS_ENUM(NSInteger, ACCServerRecordMode)
{
    ACCServerRecordModeLongPress = 1,
    ACCServerRecordModePhoto,
    ACCServerRecordModeStory,
    ACCServerRecordModeLive,
    ACCServerRecordModeStoryBoom,
    ACCServerRecordModeStoryScene,
    ACCServerRecordModeQuick,
    ACCServerRecordModeCombine,
    ACCServerRecordModeCombine15,
    ACCServerRecordModeCombine60,
    ACCServerRecordModeCombine180,
    ACCServerRecordModeText,
    ACCServerRecordModeStitch,
    ACCServerRecordModeGreenScreen,
    ACCServerRecordModeLivePhoto,
};

static NSNotificationName const ACCStickerViewControllerDidShow = @"ACCStickerViewControllerDidShow";
static NSNotificationName const ACCStickerSwitchButtonClicked = @"ACCStickerSwitchButtonClicked";
static NSNotificationName const ACCStickerViewControllerDidChangeSelection = @"ACCStickerViewControllerDidChangeSelection";
static NSString *const ACCNotificationCurrentStickerIDKey = @"ACCNotificationCurrentStickerIDKey";

static NSNotificationName const ACCMusicViewControllerDidShow = @"ACCMusicViewControllerDidShow";
static NSNotificationName const ACCMusicViewControllerDidChangeSelection = @"ACCMusicViewControllerDidChangeSelection";
static NSNotificationName const ACCMusicSelectionViewDidShow = @"ACCMusicSelectionViewDidShow";
static NSNotificationName const ACCMusicSelectionViewDidShowDidChangeSelection = @"ACCMusicSelectionViewDidShowDidChangeSelection";
static NSString *const ACCNotificationCurrentMusicIDKey = @"ACCNotificationCurrentMusicIDKey";


static NSNotificationName const ACCMVViewControllerDidShow = @"ACCMVViewControllerDidShow";
static NSNotificationName const ACCMVViewControllerDidChangeSelection = @"ACCMVViewControllerDidChangeSelection";
static NSNotificationName const ACCResourceUploadViewControllerDidShow = @"ACCResourceUploadViewControllerDidShow";
static NSNotificationName const ACCRecordUploadButtonComponentDidMount = @"ACCRecordUploadButtonComponentDidMount";
static NSNotificationName const ACCRecordUploadButtonComponentDidShow = @"ACCRecordUploadButtonComponentDidShow";
static NSNotificationName const ACCStickerComponentDidEdited = @"ACCStickerComponentDidEdited";
static NSNotificationName const ACCStickerComponentDidDeleted = @"ACCStickerComponentDidDeleted";
static NSNotificationName const ACCVideoRecorderViewControllerModeDidChange = @"ACCVideoRecorderViewControllerModeDidChange";
static NSNotificationName const ACCResourceUploadViewControllerDidSelectSingleImageAsset = @"ACCResourceUploadViewControllerDidSelectSingleImageAsset";

static NSNotificationName const ACCVideoPublishViewControllerDidEditVideoDescription = @"ACCVideoPublishViewControllerDidEditVideoDescription";

static NSString *const ACCNotificationPublishViewModelKey = @"ACCNotificationPublishViewModelKey";
static NSString *const ACCNotificationPublishDeletedUserKey = @"ACCNotificationPublishDeletedUserKey";
static NSString *const ACCNotificationVideoRecorderViewControllerNewModeKey = @"ACCNotificationVideoRecorderViewControllerNewModeKey";
static NSString *const ACCNotificationVideoRecorderViewControllerOldModeKey = @"ACCNotificationVideoRecorderViewControllerOldModeKey";
static NSString *const ACCNotificationVideoRecorderViewControllerIsReshoot = @"ACCNotificationVideoRecorderViewControllerIsReshoot";
static NSString *const ACCNotificationMVViewControllerCurrentMVIDKey = @"ACCNotificationMVViewControllerCurrentMVKey";
