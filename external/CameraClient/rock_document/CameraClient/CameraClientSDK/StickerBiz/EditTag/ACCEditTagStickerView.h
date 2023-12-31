//
//  ACCEditTagStickerView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by 卜旭阳 on 2021/10/6.
//

#import <UIKit/UIKit.h>
#import "AWEInteractionEditTagStickerModel.h"
#import "ACCStickerEditContentProtocol.h"
#import "ACCEditTagStickerViewProtocol.h"

@interface ACCEditTagStickerView : UIView <ACCStickerEditContentProtocol, ACCEditTagStickerViewProtocol>

@property (nonatomic, strong, nullable, readonly) AWEInteractionEditTagStickerModel *interactionStickerModel;

@property (nonatomic, assign) CGFloat maxContentWidth;
@property (nonatomic, assign) CGFloat maxTextWidth;
@property (nonatomic, assign) NSUInteger numberOfLines;

- (CGPoint)normalizedTagCenterPoint;

- (void)updateInteractionModel:(nullable AWEInteractionEditTagStickerModel *)interactionStickerModel;

@end
