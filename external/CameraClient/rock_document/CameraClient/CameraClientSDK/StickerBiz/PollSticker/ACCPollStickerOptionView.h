//
//  ACCPollStickerOptionView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionVoteStickerInfoModel;
@class AWEInteractionVoteStickerOptionsModel;

@interface ACCPollStickerOptionView : UIView

@property (nonatomic, strong, readonly) AWEInteractionVoteStickerOptionsModel *option;
@property (nonatomic, strong, readonly) AWEInteractionVoteStickerInfoModel *voteInfo;

- (void)configWithOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo;
- (void)performSelectionAnimationWithOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
