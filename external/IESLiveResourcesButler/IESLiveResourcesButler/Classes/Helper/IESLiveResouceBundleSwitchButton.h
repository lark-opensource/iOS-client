//
//  IESLiveResouceBundleSwitchButton.h
//  Pods
//
//  Created by Zeus on 2016/12/28.
//
//

#import <UIKit/UIKit.h>

@interface IESLiveResouceBundleSwitchButton : UIButton

@property (nonatomic, copy) void (^bundleDidSwiched)(NSString *newBundleName);
@property (nonatomic, weak) UIViewController *sourceViewController;

- (instancetype)initWithCategory:(NSString *)category;

@end
