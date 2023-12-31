//
//  ACCPollStickerViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/16.
//

#ifndef ACCPollStickerViewProtocol_h
#define ACCPollStickerViewProtocol_h
#import "ACCStickerContentDisplayProtocol.h"

@class AWEInteractionVoteStickerOptionsModel, AWEInteractionVoteStickerInfoModel;

@protocol ACCPollStickerViewProtocol <ACCStickerContentDisplayProtocol>

- (void)selectOption:(AWEInteractionVoteStickerOptionsModel *)option voteInfo:(AWEInteractionVoteStickerInfoModel *)voteInfo completion:(void (^)(void))completion;

- (AWEInteractionVoteStickerOptionsModel *)tappedVoteInfoForTappedPoint:(CGPoint)point;

@end


#endif /* ACCPollStickerViewProtocol_h */
