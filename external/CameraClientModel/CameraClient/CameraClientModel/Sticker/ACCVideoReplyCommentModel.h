//  视频回复评论二期
//  ACCVideoReplyCommentModel.h
//  CameraClientModel-Pods-Aweme
//
//  Created by lixuan on 2021/10/8.
//

#import <Mantle/Mantle.h>
#import <Mantle/MTLJSONAdapter.h>
#import <CameraClientModel/ACCVideoReplyStickerReplyType.h>

@class AWEURLModel;

typedef NS_ENUM(NSInteger, ACCVideoReplyCommentViewType) {
    ACCVideoReplyCommentViewTypeWithoutCover = 1, // 视频回复评论二期贴纸样式一
    ACCVideoReplyCommentViewTypeWithCover = 2, // 视频回复评论二期贴纸样式二
};

@interface ACCVideoReplyCommentModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSString *commentId; // 被回复的评论的ID
@property (nonatomic, copy, nullable) NSString *commentText; // 被回复的评论的内容
@property (nonatomic, copy, nullable) NSString *commentUserId; // 被回复的评论的作者ID
@property (nonatomic, copy, nullable) NSString *commentAuthorNickname; // 被回复的评论的作者昵称
@property (nonatomic, copy, nullable) AWEURLModel *commentAuthorAvatar; // 被回复的评论的作者头像的链接
@property (nonatomic, copy, nullable) NSString *awemeId; // 原视频的ID
@property (nonatomic, copy, nullable) NSString *commentToCommentId; // 回复类型的评论二级评论ID
@property (nonatomic, copy, nullable) NSString *awemeTitle; // 原视频的标题，样式1使用
@property (nonatomic, copy, nullable) AWEURLModel *coverModel; // 原视频的封面图的链接，样式2使用
@property (nonatomic, copy, nullable) AWEURLModel *commentSticker; // 评论表情内容，样式1展示表情原图，样式2展示[表情]两个字
@property (nonatomic, assign) ACCVideoReplyStickerReplyType replyType; // 视频回复评论贴纸还是视频回复视频贴纸

@property (nonatomic, copy, nullable) NSString *aliasCommentId; // 假写的评论ID
@property (nonatomic, assign) ACCVideoReplyCommentViewType viewType; // 贴纸UI样式
@property (nonatomic, assign, getter=isDeleted) BOOL deleted; // 视频回复评论贴纸是否被删除
@property (nonatomic, assign) BOOL isAvailable; // 原视频是否可以播放

@end

 
