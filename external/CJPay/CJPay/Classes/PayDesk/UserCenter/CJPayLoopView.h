//
//  CJPayLoopView.h
//  CJPay
//
//  Created by 王新华 on 2019/4/26.
//

#import <Foundation/Foundation.h>
#import "CJPayIndicatorView.h"

@class CJPayLoopView;

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayLoopViewDelegate <NSObject>

- (void)loopView:(CJPayLoopView *)loopView bannerAppearAtIndex:(NSUInteger)index atPage:(NSUInteger)pageNum;

@end


@interface CJPayLoopView : UIView

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, weak) id<CJPayLoopViewDelegate> delegate;
@property (nonatomic, weak, nullable) id<CJPayIndicatorViewDelegate> indicatorDelegate;

- (void)updateSubViews:(NSArray<UIView *> *)views
             durations:(nullable NSArray<NSNumber *> *)durations
       startAutoScroll:(BOOL)yesOrNo;
- (void)startAutoScroll;
- (void)stopAutoScroll;

@end

NS_ASSUME_NONNULL_END
