//
//  AWETextField.h
//  Aweme
//
//  Created by 旭旭 on 2017/9/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWETextField : UITextField

@property (nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;
//在设置placeHolderTextColor之前先设置placeholder的文案
@property (nonatomic, strong) UIColor *placeHolderTextColor;

@end
