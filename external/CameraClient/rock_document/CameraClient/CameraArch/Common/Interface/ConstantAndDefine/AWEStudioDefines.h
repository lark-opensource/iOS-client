//
//  AWEStudioDefines.h
//  CameraClient
//
//  Created by Howie He on 2021/3/22.
//

#ifndef AWEStudioDefines_h
#define AWEStudioDefines_h

#ifndef kAWEStudioPOI
#define kAWEStudioPOI @"poi_page"
#endif

// 贴纸内容审核类型，与服务端stickerTypeEnum对应
typedef NS_ENUM(NSInteger, AWEVideoPublisherTextType) {
    AWEVideoPublisherTextTypeBubbleMessage = 1,  // bubble message
    AWEVideoPublisherTextTypePoll = 3,  //投票贴纸内容
    AWEVideoPublisherTextTypeText = 4,  //文字贴纸内容
    AWEVideoPublisherTextTypeCaption = 5,   //字幕内容
    AWEVideoPublisherTextTypeStatusText = 6, //status 文字
    AWEVideoPublisherTextTypeCutSame = 7, // 剪同款 文字编辑
    AWEVideoPublisherTextTypeCommentSticker = 8, // 评论贴纸
    AWEVideoPublisherTextTypeCoverText = 9, // 封面文字
    AWEVideoPublisherTextTypeMentionSticker = 10, // Mention sticker
    AWEVideoPublisherTextTypeHashtagSticker = 11, // Hashtag sticker
    AWEVideoPublisherTextTypeCountDown = 12, // Count Down Title
    AWEVideoPublisherTextTypeAlbumImageSticker = 13, // 图集 sticker
    AWEVideoPublisherTextTypeQuestion = 14, // Q & A
    AWEVideoPublisherTextTypeMusicStoryCoverText = 18, // cover info for music story publish
    AWEVideoPublisherTextTypeShareCommentToStoryCommentInfo = 20, // 分享评论到日常评论信息
    AWEVideoPublisherTextTypeTags = 21, // 标记
};

#endif /* AWEStudioDefines_h */
