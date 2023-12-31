//
//  DVEEditStickerBubbleManager.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/5.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSString * _Nonnull const DVEEditVideoStickerBubbleManagerName;
FOUNDATION_EXTERN NSString * _Nonnull const DVEEditTextStickerBubbleManagerName;
FOUNDATION_EXTERN NSString * _Nonnull const DVEEditInteractiveVideoStickerBubbleManagerName;

@class DVEEditStickerBubbleItem;

typedef NS_ENUM(NSUInteger, DVEEditStickerBubbleArrowDirection) {
    DVEEditStickerBubbleArrowDirectionUp,
    DVEEditStickerBubbleArrowDirectionDown,
};

NS_ASSUME_NONNULL_BEGIN

@protocol DVEEditStickerBubbleProtocol <NSObject>

@property (nonatomic, getter=isBubbleVisible) BOOL bubbleVisible;        // default is NO

@property (nonatomic, assign) DVEEditStickerBubbleArrowDirection arrowDirection;

@property (nonatomic, copy) NSArray<DVEEditStickerBubbleItem *> *bubbleItems;

- (void)setBubbleVisible:(BOOL)bubbleVisible animated:(BOOL)animated;

/**
 设置弹窗的必要参数
 @param rect parentView坐标系下的rect,请保证是transform identity的
 @param touchPoint parentView坐标系下的touchPoint
 @param transform 锚定view的transform
 @param parentView 展示弹窗的父view,坐标最后都要转到该坐标系下
 */
- (void)setRect:(CGRect)rect
     touchPoint:(CGPoint)touchPoint
      transform:(CGAffineTransform)transform
   inParentView:(UIView *)parentView;

- (void)update;

- (BOOL)handleTapGestureIfNeed:(UITapGestureRecognizer *)tapGesture;

@end

FOUNDATION_EXPORT NSString * const DVEEditStickerBubbleVisableDidChangedNotify;
FOUNDATION_EXPORT NSString * const DVEEditStickerBubbleVisableDidChangedNotifyGetNameKey;
FOUNDATION_EXPORT NSString * const DVEEditStickerBubbleVisableDidChangedNotifyGetVisableKey;

@interface DVEEditStickerBubbleManager : NSObject <DVEEditStickerBubbleProtocol>

+ (instancetype)sharedManager;

+ (instancetype)managerWithName:(NSString *)name;

- (void)destroy; ///< 内部managerArray remove一次，不对sharedManager生效

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, copy) UIView *(^defaultTargetView)(void);

@property (nonatomic, copy) CGRect (^getParentViewActualFrameBlock)(void);///< 获取可显示范围，适配刘海屏，初始化的时候设置

@end

FOUNDATION_EXPORT NSString * const DVEStickerEditingBubbleManagerName;

@interface DVEEditStickerBubbleManager (DVEEditSticker)

+ (instancetype)videoStickerBubbleManager;
+ (instancetype)interactiveStickerBubbleManager;
+ (instancetype)textStickerBubbleManager;

@end

@interface DVEEditStickerBubbleItem : NSObject

- (instancetype)initWithImage:(UIImage *)image
                        title:(NSString *)title
                  actionBlock:(dispatch_block_t)actionBlock;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) dispatch_block_t actionBlock;

@property (nonatomic, copy) NSString *actionTag;
@property (nonatomic, assign) BOOL showShakeAnimation;
@property (nonatomic, copy) dispatch_block_t shakeAniPerformedBlock;

@end

NS_ASSUME_NONNULL_END
