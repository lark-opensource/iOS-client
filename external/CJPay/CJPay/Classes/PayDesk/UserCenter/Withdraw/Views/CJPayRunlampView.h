//
//  CJPayRunlampView.h
//  CJPay
//
//  Created by 王新华 on 10/12/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRunlampView : UIView

@property (nonatomic, assign) CGFloat contentMargin;
@property (nonatomic, assign) CGFloat pointsPerFrame;

- (void)startMarqueeWith:(UIView *)view;
- (void)startMarquee;
- (void)stopMarquee;

@end

NS_ASSUME_NONNULL_END
