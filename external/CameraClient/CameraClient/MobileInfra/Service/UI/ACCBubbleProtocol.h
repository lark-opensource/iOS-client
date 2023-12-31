//
//  ACCBubbleProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCBubbleDirection) {
    ACCBubbleDirectionUp,
    ACCBubbleDirectionDown,
    ACCBubbleDirectionLeft,
    ACCBubbleDirectionRight,
};


typedef NS_ENUM(NSUInteger, ACCBubbleBGStyle) {
    ACCBubbleBGStyleDefault,
    ACCBubbleBGStyleDark,
};

@protocol ACCBubbleProtocol <NSObject>

#pragma mark - create bubble and display
- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
      anchorAdjustment:(CGPoint)adjustment
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
      anchorAdjustment:(CGPoint)adjustment
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style
            completion:(void (^)(void))completion;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
       inContainerView:(UIView *)containerView
      anchorAdjustment:(CGPoint)adjustment
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style
            completion:(nullable void (^)(void))completion;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
       inContainerView:(UIView *)containerView
      anchorAdjustment:(CGPoint)adjustment
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style
          showDuration:(CGFloat)duration
            completion:(nullable void (^)(void))completion;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
       inContainerView:(UIView *)containerView
      anchorAdjustment:(CGPoint)adjustment
           inDirection:(ACCBubbleDirection)bubbleDirection
               bgStyle:(ACCBubbleBGStyle)style
         numberOfLines:(NSUInteger)numbrOfLiens
            completion:(nullable void (^)(void))completion;

- (UIView *)showBubbleWithCustomView:(UIView *)customView
                       contentInsets:(UIEdgeInsets)insets
                             forView:(UIView *)view
                     inContainerView:(UIView *)containerView
                          fromAnchor:(CGPoint)anchor
                         inDirection:(ACCBubbleDirection)bubbleDirection
                    anchorAdjustment:(CGPoint)adjustment
                             bgStyle:(ACCBubbleBGStyle)style
                          completion:(nullable void(^)(void))completion;

- (UIView *)showBubbleWithCustomView:(UIView *)customView
                       contentInsets:(UIEdgeInsets)insets
                             forView:(UIView *)view
                     inContainerView:(UIView *)containerView
                          fromAnchor:(CGPoint)anchor
                         inDirection:(ACCBubbleDirection)bubbleDirection
                    anchorAdjustment:(CGPoint)adjustment
                    cornerAdjustment:(CGPoint)cornerAdjustment
                             bgStyle:(ACCBubbleBGStyle)style
                          completion:(nullable void(^)(void))completion;

- (UIView *)showBubble:(NSString *)title
               forView:(UIView *)view
              iconView:(UIView *)iconView
        iconViewInsets:(UIEdgeInsets)insets
            fromAnchor:(CGPoint)anchor
      anchorAdjustment:(CGPoint)anchorDdjustment
      cornerAdjustment:(CGPoint)cornerAdjustment
             fixedSize:(CGSize)fixedSize
             direction:(ACCBubbleDirection)direction
               bgStyle:(ACCBubbleBGStyle)style
            completion:(nullable dispatch_block_t)completion;

- (UIView *)showBubble:(NSString *)title
               forView:(UIView *)view
              iconView:(UIView *)iconView
       inContainerView:(UIView *)containerView
        iconViewInsets:(UIEdgeInsets)insets
            fromAnchor:(CGPoint)anchor
      anchorAdjustment:(CGPoint)anchorDdjustment
      cornerAdjustment:(CGPoint)cornerAdjustment
             fixedSize:(CGSize)fixedSize
             direction:(ACCBubbleDirection)direction
               bgStyle:(ACCBubbleBGStyle)style
            completion:(dispatch_block_t)completion;

- (UIView *)showBubble:(NSString *)title
               forView:(UIView *)view
              iconView:(UIView *)iconView
       inContainerView:(UIView *)containerView
        iconViewInsets:(UIEdgeInsets)insets
            fromAnchor:(CGPoint)anchor
      anchorAdjustment:(CGPoint)anchorDdjustment
      cornerAdjustment:(CGPoint)cornerAdjustment
             fixedSize:(CGSize)fixedSize
             direction:(ACCBubbleDirection)direction
               bgStyle:(ACCBubbleBGStyle)style
          showDuration:(CGFloat)duration
            completion:(dispatch_block_t)completion;

- (UIView *)showBubble:(NSString *)title
               forView:(UIView *)view
            fromAnchor:(CGPoint)anchor
      anchorAdjustment:(CGPoint)anchorAdjustment
      cornerAdjustment:(CGPoint)cornerAdjustment
             fixedSize:(CGSize)fixedSize
           inDirection:(ACCBubbleDirection)direction
               bgStyle:(ACCBubbleBGStyle)style
            completion:(nullable dispatch_block_t)completion;

- (UIView *)showAttributedBubble:(NSAttributedString *)content
                    withCustomImage:(UIImage *)image
                        imageInsets:(UIEdgeInsets)imageEdgeInsets
                         textInsets:(UIEdgeInsets)textInsets
                          fixedSize:(CGSize)fixedSize
                     needFixedWidth:(BOOL)needFixedWidth
                            forView:(UIView *)view
                    inContainerView:(UIView *)containerView
                         fromAnchor:(CGPoint)anchor
                        inDirection:(ACCBubbleDirection)bubbleDirection
                   anchorAdjustment:(CGPoint)adjustment
                         completion:(nullable dispatch_block_t)completion;

- (UIView *)showBubble:(NSString *)content
               forView:(UIView *)view
       inContainerView:(UIView *)containerView
            fromAnchor:(CGPoint)anchor
      anchorAdjustment:(CGPoint)adjustment
      cornerAdjustment:(CGPoint)cornerAdjustment
             fixedSize:(CGSize)fixedSize
           inDirection:(ACCBubbleDirection)bubbleDirection
      isDarkBackGround:(BOOL)isDarkBackGround
            completion:(void(^)(void))completion;

- (void)bubble:(UIView *)bubble textAlignment:(NSTextAlignment)alignment;
- (void)bubble:(UIView *)bubble textNumberOfLines:(NSInteger)numberOfLines;

#pragma mark - bubble operation
- (void)removeBubble:(UIView *)bubble;

- (void)bubble:(UIView *)bubble supportTapToDismiss:(BOOL)tap;

- (void)tapToDismissWithBubble:(UIView *)bubble;

- (void)redoLayout:(UIView *)bubble;

@end

FOUNDATION_STATIC_INLINE id<ACCBubbleProtocol> ACCBubble() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCBubbleProtocol)];
}

NS_ASSUME_NONNULL_END
