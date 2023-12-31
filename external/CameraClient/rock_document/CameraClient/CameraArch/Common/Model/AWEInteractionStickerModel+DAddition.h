//
//  AWEInteractionStickerModel+DAddition.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/21.
//

#import <CreationKitArch/AWEInteractionStickerModel.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, AWEInteractionStickerType) {
    AWEInteractionStickerTypeNone = 0,
    AWEInteractionStickerTypeProps = 2,//道具
    AWEInteractionStickerTypePoll = 3,//投票贴纸
    AWEInteractionStickerTypeComment = 4,//评论贴纸，创作者用视频回复评论，原评论会作为贴纸出现在视频中
    AWEInteractionStickerTypeVideoVote = 7,
    AWEInteractionStickerTypeMention = 8,   //Mention Sticker
    AWEInteractionStickerTypeHashtag = 9,   //Hashtag Sticker
    AWEInteractionStickerTypeDaily = 10,    // Daily Sticker, a kind of Info Sticker; OFFLINE, will no longer use
    AWEInteractionStickerTypeLive = 11, // Live Sticker
    AWEInteractionStickerTypeSocialText = 13, // text sticker, which bind mentions or hashtags
    AWEInteractionStickerTypeGroot = 14, // Groot Species Sticker
    AWEInteractionStickerTypeVideoShare = 15, //share video from feeds as a story
    AWEInteractionStickerTypeVideoReply = 16, // 视频评论视频贴纸，包含了原视频的封面和相关信息
    AWEInteractionStickerTypeVideoReplyComment = 17, // 视频回复评论二期贴纸，包含被回复评论和原视频信息 TODO-check
    AWEInteractionStickerTypeEditTag = 19 // 挂件
};

@class AWEInteractionStickerLocationModel;

@interface AWEInteractionStickerModel (DAddition)

+ (NSComparisonResult)compareIndexOfSticker1:(AWEInteractionStickerModel *)sticker1 sticker2:(AWEInteractionStickerModel *)sticker2;
- (NSInteger)indexFromType;
- (AWEInteractionStickerLocationModel *)generateLocationModel;
- (void)updateLocationInfo:(AWEInteractionStickerLocationModel *)location;
@end

NS_ASSUME_NONNULL_END
