//
//  CJPaySwitch.h
//  Pods
//
//  Created by youerwei on 2021/7/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySwitch : UIControl

@property (nonatomic, assign, getter=isOn) BOOL on;
@property (nonatomic, strong) UIColor *onTintColor UI_APPEARANCE_SELECTOR;

@end

NS_ASSUME_NONNULL_END
