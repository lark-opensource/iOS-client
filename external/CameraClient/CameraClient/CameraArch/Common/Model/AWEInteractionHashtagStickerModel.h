//
//  AWEInteractionHashtagStickerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/4/27.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEInteractionHashtagStickerModel : AWEInteractionStickerModel

@property (nonatomic, copy) NSDictionary *hashtagInfo;  //@{@"hashtag_id" : @"", @"hashtag_name" : @""}

@end

NS_ASSUME_NONNULL_END
