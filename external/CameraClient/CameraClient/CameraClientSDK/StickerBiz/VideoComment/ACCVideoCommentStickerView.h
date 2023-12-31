//
//  ACCVideoCommentStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import <UIKit/UIKit.h>

#import <CameraClientModel/ACCVideoCommentModel.h>
#import "ACCStickerEditContentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoCommentStickerView : UIView <ACCStickerEditContentProtocol>

- (void)configWithModel:(ACCVideoCommentModel *)videoCommentModel completion:(nullable void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
