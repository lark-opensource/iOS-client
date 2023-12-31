//
//  AWEEditStickerBubbleView.h
//  Pods
//
//  Created by 赖霄冰 on 2019/9/3.
//

#import <UIKit/UIKit.h>
@class AWEEditStickerBubbleItem;

typedef NS_ENUM(NSUInteger, AWEEditStickerBubbleArrowDirection) {
    AWEEditStickerBubbleArrowDirectionUp,
    AWEEditStickerBubbleArrowDirectionDown,
};

NS_ASSUME_NONNULL_BEGIN

@protocol AWEEditStickerBubbleProtocol <NSObject>

@property (nonatomic, getter=isBubbleVisible) BOOL bubbleVisible;        // default is NO
- (void)setBubbleVisible:(BOOL)bubbleVisible animated:(BOOL)animated;

/**
 设置弹窗的必要参数

 @param rect parentView坐标系下的rect,请保证是transform identity的
 @param touchPoint parentView坐标系下的touchPoint
 @param transform 锚定view的transform
 @param parentView 展示弹窗的父view,坐标最后都要转到该坐标系下
 */
- (void)setRect:(CGRect)rect touchPoint:(CGPoint)touchPoint transform:(CGAffineTransform)transform inParentView:(UIView *)parentView;
@property (nonatomic, assign) AWEEditStickerBubbleArrowDirection arrowDirection;
@property (nonatomic, copy) NSArray<AWEEditStickerBubbleItem *> *bubbleItems;
- (void)update;

@end


FOUNDATION_EXPORT NSString *const ACCEditStickerBubbleVisableDidChangedNotify;
FOUNDATION_EXPORT NSString *const ACCEditStickerBubbleVisableDidChangedNotifyGetNameKey;
FOUNDATION_EXPORT NSString *const ACCEditStickerBubbleVisableDidChangedNotifyGetVisableKey;

@interface AWEEditStickerBubbleManager : NSObject<AWEEditStickerBubbleProtocol>

+ (instancetype)sharedManager;

+ (instancetype)managerWithName:(NSString *)name;
- (void)destroy; ///< 内部managerArray remove一次，不对sharedManager生效

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong) UIView *(^defaultTargetView)(void);
@property (nonatomic, strong) CGRect (^getParentViewActualFrameBlock)(void);///< 获取可显示范围，适配刘海屏，初始化的时候设置

@end

FOUNDATION_EXPORT NSString *const ACCStickerEditingBubbleManagerName;

@interface AWEEditStickerBubbleManager (AWEEditSticker)

+ (instancetype)videoStickerBubbleManager;
+ (instancetype)interactiveStickerBubbleManager;
+ (instancetype)textStickerBubbleManager;

@end

@interface AWEEditStickerBubbleItem : NSObject

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title actionBlock:(dispatch_block_t)actionBlock;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) dispatch_block_t actionBlock;

@property (nonatomic, copy) NSString *actionTag;
@property (nonatomic, assign) BOOL showShakeAnimation;
@property (nonatomic, copy) dispatch_block_t shakeAniPerformedBlock;

@end

NS_ASSUME_NONNULL_END
