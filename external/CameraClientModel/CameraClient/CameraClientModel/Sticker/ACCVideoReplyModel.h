//
//  ACCVideoReplyModel.h
//  CameraClientModel-Pods-Aweme
//
//  视频回复视频
//
//  Created by Daniel on 2021/7/27.
//

#import <Mantle/Mantle.h>
#import <Mantle/MTLJSONAdapter.h>
#import <CameraClientModel/ACCVideoReplyStickerReplyType.h>

@class AWEURLModel;

typedef NS_ENUM(NSInteger, ACCVideoReplyViewType) {
    ACCVideoReplyViewTypeMixCoverAndLabel = 0, // 视频回复视频贴纸旧样式，封面图与标题重合
    ACCVideoReplyViewTypeSeperateCoverAndLabel = 1, // 视频回复视频贴纸新样式，封面图与标题分开
};

@interface ACCVideoReplyModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *awemeId; // 被评论的视频的id, i.e. 贴纸中的视频的id
@property (nonatomic, copy, nullable) NSString *userId; // 被评论的视频的作者id
@property (nonatomic, copy, nullable) NSString *secUserId; // 被评论的视频的作者id（加密）
@property (nonatomic, copy, nullable) NSString *username; // 被评论的视频的作者名字
@property (nonatomic, copy, nullable) NSString *title; // 被评论的视频的标题
@property (nonatomic, copy, nullable) AWEURLModel *coverModel;  // 被评论的视频优先使用的封面图的链接
@property (nonatomic, assign) NSInteger awemeType;
@property (nonatomic, assign, getter=isDeleted) BOOL deleted;
@property (nonatomic, assign) BOOL isAvailable; // 原视频是否可以播放
@property (nonatomic, assign) ACCVideoReplyStickerReplyType replyType; // 视频回复评论贴纸还是视频回复视频贴纸
@property (nonatomic, copy, nullable) AWEURLModel *userAvatarModel; // 被评论的视频的作者头像，优化的贴纸UI使用
@property (nonatomic, assign) ACCVideoReplyViewType viewType; // 视频回复视频贴纸样式

// 当回复评论面板中的【视频评论视频】cell时需要补充下列信息
@property (nonatomic, copy, nullable) NSString *playingAwemeId; // 正在播放的视频的id
@property (nonatomic, copy, nullable) NSString *replyId; // 回复类型的评论一级评论idk
@property (nonatomic, copy, nullable) NSString *replyToReplyId; // 回复类型的评论二级评论id

@property (nonatomic, copy, nullable) NSString *aliasCommentId;

@end
