//
//  LKNativeAppExtensionPageRoute.m
//  LKNativeAppExtension
//
//  Created by Bytedance on 2021/12/17.
//  Copyright © 2021 Bytedance. All rights reserved.
//

@import UIKit;

@protocol LKNativeAppExtensionPageRoute <NSObject>

@required
/// 通过飞书 applink 打开自定义页面
/// @param link  applink 链接
/// @param from  来源页面
- (void)pageRoute: (NSURL *)link from:(UIViewController *)from;

@end
