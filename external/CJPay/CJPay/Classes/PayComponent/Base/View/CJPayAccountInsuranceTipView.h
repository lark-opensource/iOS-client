//
//  CJPayAccountInsuranceTipView.h
//  Pods
//
//  Created by 王新华 on 2021/3/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAccountInsuranceTipView : UIView

@property (nonatomic, assign) BOOL showEnable;

+ (NSString *)keyboardLogo;

+ (BOOL)shouldShow;

- (void)darkThemeOnly;

@end

NS_ASSUME_NONNULL_END
