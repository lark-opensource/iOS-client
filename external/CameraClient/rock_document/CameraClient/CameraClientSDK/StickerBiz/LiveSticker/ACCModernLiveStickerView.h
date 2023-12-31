//
//  ACCModernLiveStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/14.
//

#import "ACCLiveStickerView.h"

@class AWEInteractionStickerModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCModernLiveStickerView : ACCLiveStickerView

+ (ACCLiveStickerView *)createLiveStickerViewWithModel:(AWEInteractionStickerModel *)model;

@end

NS_ASSUME_NONNULL_END
