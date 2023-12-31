//
//  ACCLiveStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import <UIKit/UIKit.h>
#import "ACCLiveStickerViewProtocol.h"
#import "ACCStickerEditContentProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLiveStickerView : UIView<ACCStickerEditContentProtocol, ACCLiveStickerViewProtocol>

@property (nonatomic, strong, readonly) AWEInteractionLiveStickerInfoModel *liveInfo;

@property (nonatomic, copy) NSString *extraAttr;

@property (nonatomic, assign) BOOL hasEdited;

@property (nonatomic, strong, nullable) UIView *inputView;
@property (nonatomic, strong, nullable) UIView *inputAccessoryView;

- (void)configWithInfo:(AWEInteractionLiveStickerInfoModel *)liveInfo;

- (void)changeResponderStatus:(BOOL)responder;

- (void)transportToEditWithSuperView:(UIView *)superView
                   animationDuration:(CGFloat)duration
                           animation:(void (^)(void))animationBlock
                          completion:(void (^)(void))completion;

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
                completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
