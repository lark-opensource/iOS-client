//
//  DVESegmentClipView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/16.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, DVESegmentClipViewMode) {
    DVESegmentClipViewModeNormal,
    DVESegmentClipViewModeClip,
};

typedef NS_ENUM(NSUInteger, DVESegmentClipViewPanPosition) {
    DVESegmentClipViewPanPositionLeft,
    DVESegmentClipViewPanPositionRight,
};

typedef NS_ENUM(NSUInteger, DVESegmentClipViewArrowStyle) {
    DVESegmentClipViewArrowStyleDefault,
    DVESegmentClipViewArrowStyleSample,
};

@class DVESegmentClipView;
@protocol DVESegmentClipViewDelegate <NSObject>

- (void)segmentClipView:(DVESegmentClipView *_Nonnull)segmentClipView
                gesture:(UIPanGestureRecognizer *_Nonnull)gesture
               position:(DVESegmentClipViewPanPosition)position;

@end


NS_ASSUME_NONNULL_BEGIN

@interface DVESegmentClipView : UIView

@property (nonatomic, assign, readonly) CGFloat space;
@property (nonatomic, assign, readonly) CGFloat lineHeight;
@property (nonatomic, assign, readonly, class) CGFloat arrowWidth;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, weak) id<DVESegmentClipViewDelegate> delegate;
@property (nonatomic, assign) DVESegmentClipViewMode mode;

- (instancetype)initWithMode:(DVESegmentClipViewMode)mode;

- (instancetype)initWithMode:(DVESegmentClipViewMode)mode style:(DVESegmentClipViewArrowStyle)style;

- (void)showWithAnimated:(BOOL)animated completion:(nullable void(^)(void))completion;

- (void)dismissWithAnimated:(BOOL)animated completion:(nullable void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
