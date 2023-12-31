//
//  AWEInteractionMentionStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/27.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEInteractionMentionStickerModel : AWEInteractionStickerModel

// text_content 为完整的输入内容 用于送审
@property (nonatomic, copy) NSDictionary *mentionedUserInfo; //@{@"user_id" : @"", @"user_name" : @"", @"sec_uid" : @"", @"followStatus" : @(0), @"text_content" : @""}

@end

NS_ASSUME_NONNULL_END
