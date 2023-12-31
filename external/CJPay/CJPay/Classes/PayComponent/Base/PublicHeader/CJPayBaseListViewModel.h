//
//  CJPayBaseListViewModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/18.
//

#import <Foundation/Foundation.h>

@class CJPayBaseListCellView;
@class CJPayCommonListViewController;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseListViewModel : NSObject

@property(nonatomic, weak) CJPayCommonListViewController *viewController;

@property(nonatomic) Class viewClass;
@property(nonatomic, weak) CJPayBaseListCellView *cell;
@property(nonatomic, assign) CGFloat viewHeight;
@property(nonatomic, assign) CGFloat topMarginHeight;
@property(nonatomic, assign) CGFloat bottomMarginHeight;
@property(nonatomic, strong) UIColor *topMarginColor;
@property(nonatomic, strong) UIColor *bottomMarginColor;

- (instancetype)initWithViewController:(CJPayCommonListViewController *)vc;

- (Class)getViewClass;

- (CGFloat)getViewHeight;

- (CGFloat)getTopMarginHeight;

- (CGFloat)getBottomMarginHeight;

- (UIColor *)getTopMarginColor;

- (UIColor *)getBottomMarginColor;

@end

NS_ASSUME_NONNULL_END
