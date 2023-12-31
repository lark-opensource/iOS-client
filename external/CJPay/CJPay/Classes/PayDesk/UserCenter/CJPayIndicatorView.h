//
//  CJPayIndicatorView.h
//  CJPay
//
//  Created by 王新华 on 2019/5/5.
//

#import <Foundation/Foundation.h>

@protocol CJPayIndicatorViewDelegate <NSObject>

- (void)configCount:(NSInteger) count;

- (void)didScrollTo:(NSInteger) index;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CJPayIndicatorView : UIView<CJPayIndicatorViewDelegate>

@property (nonatomic, assign) CGFloat spacing;

@end

NS_ASSUME_NONNULL_END
