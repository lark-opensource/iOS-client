//
//  ACCVideoCommentModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <Mantle/MTLJSONAdapter.h>
#import <CameraClientModel/ACCVideoReplyStickerReplyType.h>

NS_ASSUME_NONNULL_BEGIN

/* ------ ACCVideoCommentModel ------ */

@interface ACCVideoCommentModel : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *userId; // 被回复的作者id
@property (nonatomic, copy) NSString *userName; // 被回复的作者名字
@property (nonatomic, copy) NSArray *avatarURLList; // 被回复的作者头像
@property (nonatomic, copy) NSString *commentMsg; // 评论的内容
@property (nonatomic, copy) NSString *commentId; // 被回复的评论的id
@property (nonatomic, copy) NSString *awemeId; // 被回复的视频的id
@property (nonatomic, copy) NSString *replyId; //回复类型的评论一级评论idk
@property (nonatomic, copy) NSString *replyToReplyId; //回复类型的评论二级评论id
@property (nonatomic, assign) NSInteger channelId; // 请求渠道
// @property (nonatomic, strong) NSString *enterMethod; // 进入方式
@property (nonatomic, copy) NSArray *emojiURLList; // 评论大图表情
@property (nonatomic, assign) ACCVideoReplyStickerReplyType replyType; // 视频回复评论贴纸还是视频回复视频贴纸

/*
 透传过来的埋点信息，仅用于草稿迁移
 */
@property (nonatomic, strong, nullable) NSNumber *isAuthor; // BOOL
@property (nonatomic, strong, nullable) NSNumber *relationTag; // NSInteger
@property (nonatomic, strong, nullable) NSNumber *isDeleted; // BOOL，仅在草稿迁移时取/赋值

+ (nullable ACCVideoCommentModel *)createModelFromJSON:(NSString *)jsonStr;
- (NSString *)convertToJSONString;

@end

NS_ASSUME_NONNULL_END
