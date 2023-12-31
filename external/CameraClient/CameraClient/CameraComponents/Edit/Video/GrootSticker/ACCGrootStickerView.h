//
//  ACCGrootStickerView.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/14.
//

#import <UIKit/UIKit.h>
#import "ACCStickerEditContentProtocol.h"
#import "ACCGrootStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCGrootStickerView : UIView <ACCStickerEditContentProtocol>

@property (nonatomic, strong, readonly) ACCGrootStickerModel *stickerModel;
@property (nonatomic, copy,   readonly) NSString * grootStickerUniqueId;
@property (nonatomic, assign, readonly) CGFloat currentScale;

- (instancetype)initWithStickerModel:(nonnull ACCGrootStickerModel *)stickerModel
               grootStickerUniqueId:(nullable NSString *)grootStickerUniqueId;

- (void)transportToEditWithSuperView:(UIView *)superView
                           animation:(void (^)(void))animationBlock
          selectedViewAnimationBlock:(void (^)(void))selectedViewAnimationBlock
                   animationDuration:(CGFloat)duration;

- (void)restoreToSuperView:(UIView *)superView
         animationDuration:(CGFloat)duration
            animationBlock:(void (^)(void))animationBlock
selectedViewAnimationBlock:(void (^)(void))selectedViewAnimationBlock
                completion:(void (^)(void))completion;

- (void)configGrootDetailsStickerModel:(ACCGrootDetailsStickerModel *)grootStickerModel  snapIsDummy:(BOOL)snapIsDummy;

- (BOOL)isFromRecord;

@end

NS_ASSUME_NONNULL_END
