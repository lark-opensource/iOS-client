//
//  ACCAwemeModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/11.
//

#ifndef ACCAwemeModelProtocol_h
#define ACCAwemeModelProtocol_h

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <objc/runtime.h>
#import "ACCChallengeModelProtocol.h"
#import "ACCVideoModelProtocol.h"

FOUNDATION_EXPORT NSString * const AWEAwemePostNotificationAwemeKey;
FOUNDATION_EXPORT NSString * const AWEAwemePostNofificationTaskIdKey;
FOUNDATION_EXPORT NSString * const AWEAwemePostNotificationNotifyKey;
FOUNDATION_EXPORT NSString * const AWEAwemePostNotification;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

// AwemeType, if you add value in this enum, plz also add in AwemeType
typedef NS_ENUM(NSInteger, ACCFeedType) {
    ACCFeedTypeUnknown = -1,
    ACCFeedTypeGeneral = 0, // ordinary video (compatible old version) 
    ACCFeedTypeGDAD = 1,// GD advertising (compatible old version && naming is not suitable) 
    ACCFeedTypeImage = 2,// Graphic 
    ACCFeedTypeVideo = 4,// ordinary video 
    ACCFeedTypeStory = 11,//STORY
    ACCFeedTypeVR = 12,//VR
    ACCFeedTypeRepost = 13,// forward 
    ACCFeedTypeStoryVideo = 14,// story video 
    ACCFeedTypeStoryImage = 15,// story picture 
    ACCFeedTypeNonNativeAd = 29,// Non-original advertising 
    ACCFeedTypeNativeAd = 30,// Native advertising 
    ACCFeedTypeADX = 31,// native_ad_from_dsp DSP native ad 
    ACCFeedTypeTalent = 32, // Soft Marketing (Red Man) 
    ACCFeedTypeMaterial = 33, // Advertising host videos 
    ACCFeedTypeNonNativeADX = 34, // Non-native ADX advertising
    ACCFeedTypeStoryTT = 40, // new story for tiktok
    ACCFeedTypeDuet = 51, // duet video 
    ACCFeedTypeLiveStream = 101,// Room Duet_Video = 51 # duet video 
    ACCFeedTypeReact = 52,// React Video 
    ACCFeedTypeMV = 53,// Theme template video 
    ACCFeedTypeInteractionSticker = 54,// Interactive sticker video 
    ACCFeedTypeAIMusicVideo = 55,// Smart Music Card Point Video 
    ACCFeedTypeStatus = 56,// Brazilian chicken soup video 
    ACCFeedTypeStitch = 58,// stitch video 
    ACCFeedTypeLivePlayback = 59,// live playback 
    ACCFeedTypeGreenScreen = 60, // Cream mode video 
    ACCFeedTypePhotoToVideo = 61, //photo to video using mv template
    ACCFeedTypeMoments = 62, // moments
    ACCFeedTypeLivePlayRecord = 63,// Live recording screen 
    ACCFeedTypeLivePlayBackRecord = 64,// live back recording screen 
    ACCFeedTypeLiveAdminRecord = 65, // Live manager 
    ACCFeedTypeOneClickFilming = 66, // One-button 
    ACCFeedTypeSmartMV = 67, // One-click MV 
    ACCFeedTypeImageAlbum = 68, // Atlas (non-video format) Feed 
    ACCFeedTypeRecognition = 69,  // SmartScan recognition
    ACCFeedTypeLiteTheme = 70, // aweme lite theme record
    // remove 100 and 301 because aweme type have no match type
// accfeedtypessymphonyad = 100, // symphony ad 
    ACCFeedTypeCanvasPost = 109, // Replacement of daily, text mode and other canvas submission
    ACCFeedTypeKaraoke = 110,
//    ACCFeedTypeAtlas = 150, // placeholder for the future. If you have any question, plz contact @zhangzhihao.lucas
    ACCFeedTypeSplashAd = 201, // awemsome splash 
// accfeedtypeuserrecommend = 301, // Acacia Tab full-screen push card client to log up the type, the server has no corresponding value 
    ACCFeedTypeVisitFrequentUserVideoEmpty = 401, // visit frequently user has no new video temporarily
    //401 type original author: zhangkun~ I only added a "," XD
    ACCFeedTypeHotSpotMoreRec = 501,  // Only hot internal flow uses only used in Hot Spot Feed
    ACCFeedTypeAudioMode = 118,
};

typedef NS_ENUM(NSInteger, ACCDuetAuthType) {
    ACCDuetAuthTypePermit = 0, // Allow a photo 
    ACCDuetAuthTypeForbitByAuthor = 1, // is prohibited by the author 
    ACCDuetAuthTypeForbitByAd = 2 // is prohibited by the advertising platform 
};

typedef NS_ENUM(NSUInteger, ACCPrivacyType) {
    ACCPrivacyTypePublic = 0,
    ACCPrivacyTypePrivate = 1,
    ACCPrivacyTypeFriendVisible = 2,
};

typedef NS_ENUM(NSUInteger, ACCPublishToType) {
    ACCPublishToTypeNone = 0, // Non-this function 
    ACCPublishToTypeSelf = 1, // Release to your own account 
    ACCPublishToTypeAnchor = 2, // Publish to an an an anchor 
};

typedef NS_ENUM(NSUInteger, ACCGameType) {
    ACCGameTypeNone = 0, // Is not a small game 
    ACCGameTypeCatchFruit = 1, // Game 
    ACCGameTypeEffectControlGame = 2, // Effect directly controls small games 
};

@protocol ACCAwemeModelProtocol <NSObject, MTLJSONSerializing>

@property (nonatomic, copy) NSString *itemID;
@property (nonatomic, strong) id<ACCVideoModelProtocol> video;
@property (nonatomic, copy) NSArray<id<ACCChallengeModelProtocol>> *challengeList;
@property (nonatomic, copy) NSString *stickers;
@property (nonatomic, strong) id<ACCMusicModelProtocol> music;

- (NSInteger)gameScore;

@end

#endif /* ACCAwemeModelProtocol_h */

NS_ASSUME_NONNULL_END
