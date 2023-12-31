//
//  ACCStickerBubbleProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/8/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSInteger ACCStickerBubbleAction;

@class ACCBaseStickerView;
@class ACCStickerBubbleConfig;

@protocol ACCStickerBubbleEditProtocol <NSObject>

- (void)updateBubbleWithTag:(NSString *)tag title:(nullable NSString *)title image:(nullable UIImage *)image;

@end

@protocol ACCStickerBubbleProtocol <NSObject>

- (instancetype)initWithWeakReferenceOfStickerView:(ACCBaseStickerView *)stickerView bubbleActionList:(NSArray<ACCStickerBubbleConfig *> *)bubbleActionList;

- (void)showBubbleAtPoint:(CGPoint)point;
- (void)hideAnimated:(BOOL)animated;
- (void)updateBubbleWithTag:(NSString *)tag title:(NSString *)title image:(UIImage *)image;
- (void)updateBubbleActionListIfNeeded:(NSArray<ACCStickerBubbleConfig *> *)bubbleActionList;

@end

NS_ASSUME_NONNULL_END
