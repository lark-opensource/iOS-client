//
//  BDPPhoneNumberPermissionContentView.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPPhoneNumberPermissionContentView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIImageView *phoneIconView;
@property (nonatomic, copy) NSString *phoneNumer;

- (instancetype)initWithFrame:(CGRect)frame window:(UIWindow *)window;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
