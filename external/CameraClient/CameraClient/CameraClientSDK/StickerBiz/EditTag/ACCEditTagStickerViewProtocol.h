//
//  ACCEditTagStickerViewProtocol.h
//  CameraClient
//
//  Created by 卜旭阳 on 2021/10/11.
//

#import "ACCStickerContentDisplayProtocol.h"

@protocol ACCEditTagStickerViewProtocol <ACCStickerContentDisplayProtocol>

@property (nonatomic, assign) CGFloat maxContentWidth;
@property (nonatomic, assign) CGFloat maxTextWidth;
@property (nonatomic, assign) NSUInteger numberOfLines;

- (void)showHeartAnimation;

@end
