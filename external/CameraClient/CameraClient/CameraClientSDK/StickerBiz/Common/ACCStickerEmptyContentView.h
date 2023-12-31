//
//  ACCStickerEmptyContentView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/3/9.
//

#import <UIKit/UIKit.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCStickerContentDisplayProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionStickerModel;

@interface ACCStickerEmptyContentView : UIView <ACCStickerEditContentProtocol, ACCStickerContentDisplayProtocol>

@property (nonatomic, strong) AWEInteractionStickerModel *model;

@end

NS_ASSUME_NONNULL_END
