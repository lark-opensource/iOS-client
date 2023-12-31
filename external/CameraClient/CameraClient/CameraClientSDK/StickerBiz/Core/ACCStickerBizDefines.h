//
//  ACCStickerBizDefines.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/9/24.
//

#import <Foundation/Foundation.h>
#import <CreativeKitSticker/ACCStickerBubbleProtocol.h>

typedef NS_ENUM(NSInteger, ACCStickerHierarchyType) {
    ACCStickerHierarchyTypeVeryVeryLow = -1,
    ACCStickerHierarchyTypeVeryLow = 0,
    ACCStickerHierarchyTypeLow = 1,
    ACCStickerHierarchyTypeNormal = 2, // can be applied to ve
    ACCStickerHierarchyTypeMediumHigh = 80, // can be applied to ve
    ACCStickerHierarchyTypeHigh = 90,
    ACCStickerHierarchyTypeVeryHigh = 100
};

typedef NSString* ACCStickerTypeId;

FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdText;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdSocial;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdVideoComment;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdVideoReply;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdVideoReplyComment;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdInfo;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdPOI;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdModernPOI;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdPoll;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdCaptions;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdLive;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdCanvas;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdGroot;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdGroup;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdLyric;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdKaraoke;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdEditTag;
FOUNDATION_EXTERN ACCStickerTypeId const ACCStickerTypeIdWishTitle;

typedef NS_OPTIONS(NSInteger, ACCStickerContainerFeature) {
    ACCStickerContainerFeatureNone = 0,
    ACCStickerContainerFeatureAdsorbing = 1 << 0,
    ACCStickerContainerFeatureAngleAdsorbing = 1 << 1,
    ACCStickerContainerFeatureSafeArea = 1 << 2,
    ACCStickerContainerFeatureHighlightMoment = 1 << 3,
    ACCStickerContainerFeatureAutoCaptions = 1 << 4,
    ACCStickerContainerFeatureInfoPin = 1 << 5,
    ACCStickerContainerFeatureLyricsUpdateFrame = 1 << 6,
    ACCStickerContainerFeatureReserved = 0xFF
};

typedef NS_ENUM(ACCStickerBubbleAction, ACCStickerBubbleActionBiz) {
    ACCStickerBubbleActionBizUndefined = 0,
    ACCStickerBubbleActionBizEdit = 1,
    ACCStickerBubbleActionBizSelectTime,
    ACCStickerBubbleActionBizPin,
    ACCStickerBubbleActionBizEditAutoCaptions,
    ACCStickerBubbleActionBizDelete,
    ACCStickerBubbleActionBizTextRead,
    ACCStickerBubbleActionBizTextReadCancel,
    ACCStickerBubbleActionBizMask,
    ACCStickerBubbleActionBizPreview,
};

typedef NS_ENUM(NSInteger, ACCStickerType) {
    ACCStickerTypeUnknown = 0,
    ACCStickerTypeInfoSticker = 1,
    ACCStickerTypeTextSticker = 2,
    ACCStickerTypePOISticker = 3,
    ACCStickerTypePollSticker = 4,
    ACCStickerTypeMentionSticker = 5,
    ACCStickerTypeHashtagSticker = 6,
    ACCStickerTypeCommecialPropsSticker = 7,
    ACCStickerTypeDailySticker = 8,
    ACCStickerTypeLyricSticker = 9,
    ACCStickerTypeWeatherSticker = 10,
    ACCStickerTypeCustomSticker = 11,
    ACCStickerTypeLive = 12,
    ACCStickerTypeSearchSticker = 13,
    ACCStickerTypeGrootSticker = 14,
    ACCStickerTypeWishTitleSticker = 15
};
