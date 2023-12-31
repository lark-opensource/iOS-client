//
//  BDASplashAddFansView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/3/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 加粉按钮视图，针对加粉广告使用
@interface BDASplashAddFansView : UIView

@property (nonatomic, strong, readonly) UILabel *descLabel;

/// 根据 view 数据信息更新视图
/// @param dict 数据信息
- (void)updateViewWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
