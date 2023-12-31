//
//  ACCPOIStickerView.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/15.
//

#import <UIKit/UIKit.h>
#import "ACCPOIStickerModel.h"
#import "ACCStickerEditContentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPOIStickerView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, readonly) UIView *contentView;

@property (nonatomic, assign) NSInteger stickerId;
@property (nonatomic, strong, readonly) ACCPOIStickerModel *model;

- (void)updateWithModel:(ACCPOIStickerModel *)model;

@end

NS_ASSUME_NONNULL_END
