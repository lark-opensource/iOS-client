//
//  ACCPhotoAlbumDefine.h
//  CameraClient
//
//  Created by lixingdong on 2020/6/18.
//

#ifndef ACCPhotoAlbumDefine_h
#define ACCPhotoAlbumDefine_h

// is equal AWESelectMusicVCType
typedef NS_ENUM(NSUInteger, ACCAlbumVCType) {
    // 5 Abandoned options
    // AWESelectMusicVCTypeSwitchDefalut,
    // AWESelectMusicVCTypeSwitchChallengeMusic,
    // AWESelectMusicVCTypeTitleSelect,
    // AWESelectMusicVCTypeTitleChange,
    // AWESelectMusicVCTypeTitleChallengeMusic,
    
    ACCAlbumVCTypeForMusicDetail = 5,       // @"上传", 生成照片电影（音乐详情页的样式）
    ACCAlbumVCTypeForUpload = 6,            // 直接开拍的上传
    ACCAlbumVCTypeForStory,                 //私信调起拍摄页内的上传
    ACCAlbumVCTypeForMV,                    // 经典影集
    ACCAlbumVCTypeForPixaloop,              // 绿幕道具选单图
    ACCAlbumVCTypeForAIVideoClip,           // 卡点音乐追加视频
    ACCAlbumVCTypeForVideoBG,               // 绿幕道具选视频
    ACCAlbumVCTypeForCutSame,               // 剪同款
    ACCAlbumVCTypeForCutSameChangeMaterial, // 剪同款换素材
    ACCAlbumVCTypeForCustomSticker,         // 自定义贴纸
    ACCAlbumVCTypeForPhotoToVideo,          // 照片电影
    ACCAlbumVCTypeForFirstCreative,         // 首发奖励创作路径
    ACCAlbumVCTypeForScanQR,                // 扫一扫调起相册
    ACCAlbumVCTypeForMultiAssetsPixaloop,   // 绿幕道具选多图
    ACCAlbumVCTypeForKaraokeAudioBG,        // K歌背景
    ACCAlbumVCTypeMediumReward,             // 中视频激励计划投稿
    ACCAlbumVCTypeLocalAudioExport,         // 本地音频提取
    ACCAlbumVCTypeForDuet,                  // 合拍上传导入
    ACCAlbumVCTypeForOneKeyMv,              // 影集页一键成片入口
    ACCCloudAlbumVCTypeForPrivatePage,      // 云相册
    ACCAlbumVCTypeForRecordScan,            // 拍摄页扫一扫，和 ACCAlbumVCTypeForScanQR 的区别是这个支持 iCloud 图片
    ACCAlbumVCTypeForImageAlbum,            // 图集
    ACCAlbumVCTypeForWish,                  // 许愿
};

UIKIT_EXTERN NSString * const kAWESelectMusicVCGalleryHasBeenReminded;//是否在上传按钮上使用黄点提醒

@class IESEffectModel, AWEAssetModel, AVAsset;

typedef void(^ACCAlbumDismissBlock)(void);
typedef BOOL(^ACCAlbumShouldStartClipBlock)(void);
typedef void(^ACCAlbumSelectPhotoCompletion)(AWEAssetModel * _Nullable asset);
typedef void(^ACCAlbumSelectAssetsCompletion)(NSArray<AWEAssetModel*> * _Nullable assets);
typedef void(^ACCAlbumSelectToScanCompletion)(AVAsset * _Nullable asset, UIImage * _Nullable image, BOOL isPhoto);

#endif /* ACCPhotoAlbumDefine_h */

