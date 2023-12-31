//
//  AWERecordEnterFromDefine.h
//  AWEStudio
//
// Created by Hao Yipeng on May 16, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#ifndef AWERecordEnterFromDefine_h
#define AWERecordEnterFromDefine_h

typedef NS_ENUM(NSInteger, AWERecordEnterFromType) {
    AWERecordEnterFromTypeMusicUndefined,
    AWERecordEnterFromTypeMusicCollection,
    AWERecordEnterFromTypeMusicDetail,
    AWERecordEnterFromTypeMusicMoreSounds, // More sounds
    AWERecordEnterFromTypePropCollection, // List of props collection Click to shoot
    AWERecordEnterFromTypeStickerShareReuse, // Share the same panel
    AWERecordEnterFromTypeStickerDetailOrUserDetailOrEffectArtist, // Props details page
    AWERecordEnterFromTypeChallengeDetail, // Topic details page
    AWERecordEnterFromTypeTaskDetail, // Task details page
    AWERecordEnterFromTypeQRScan,
    AWERecordEnterFromTypeFeedToolTip,
};

#endif /* AWERecordEnterFromDefine_h */
