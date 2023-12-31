//
//  CJPayNavigationBarView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/17.
//

#import <UIKit/UIKit.h>
#import "CJPayEnumUtil.h"

@class CJPayButton;

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayNavigationBarDelegate <NSObject>

- (void)back;
- (void)share;

@end

@interface CJPayNavigationBarView : UIView

@property (nonatomic, assign) CJPayViewType viewType;
@property (nonatomic, strong) CJPayButton *backBtn;
@property (nonatomic, strong) CJPayButton *shareBtn;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, assign) BOOL isCloseBackImage; // 是否是关闭图片
/**
 点击返回按钮的回调
 */
@property (nonatomic, weak) id<CJPayNavigationBarDelegate> delegate;

/**
 显示的title
 */
@property (nonatomic, copy) NSString *title;

/**
 标题的label，可以修改颜色和字体大小
 */
@property (nonatomic, strong) UILabel *titleLabel;

/**
 图片 title,  默认是隐藏的
 */
@property (nonatomic, strong, readonly) UIImageView *titleImageView;

/**
设置图片 title
 */
- (void)setTitleImage:(NSString *)imageName;

/**
 设置返回的image

 @param image 图片
 */
- (void)setLeftImage:(UIImage *)image;

- (void)hideBottomLine;

- (void)removeStatusBarPlaceView;

@end

NS_ASSUME_NONNULL_END
