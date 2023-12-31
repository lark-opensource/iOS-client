//
//  BDASplashBannerView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/3/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 开屏 view 横条，主要用于引导用户点击跳转，做提示用
@interface BDASplashBannerView : UIView

@property (nonatomic, strong, readonly) UILabel *tipsLabel;

- (instancetype)initWithStyleEdition:(NSInteger)styleEdition andIsNewUser:(BOOL)isNewUser;

- (void)setTipsText:(NSString *)text;

- (void)deleteTextShadow;

/// 针对加粉按钮，UI 单独适配大小
- (void)refreshUIForAddFans;

@end

NS_ASSUME_NONNULL_END
