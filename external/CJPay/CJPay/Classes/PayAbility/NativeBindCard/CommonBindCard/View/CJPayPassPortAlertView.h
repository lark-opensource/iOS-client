//
//  CJPayPassPortAlertView.h
//  Pods
//
//  Created by renqiang on 2020/8/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPassPortAlertView : UIView

@property (nonatomic,copy) void(^actionBlock)(void);

+ (instancetype)alertControllerWithTitle:(nullable NSString *)mainTitle withActionTitle:(nullable NSString *)actionTitle;

@end

NS_ASSUME_NONNULL_END
