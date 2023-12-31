//
//  BDPModalPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPModalPluginModel : BDPBaseJSONModel

/// 提示的标题
@property (nonatomic, copy) NSString *title;
/// 提示的内容
@property (nonatomic, copy) NSString *content;
/// 取消按钮的文字，最多 4 个字符, 可能为nil
@property (nonatomic, copy) NSString *cancelText;
/// 取消按钮的文字颜色，必须是 16 进制格式的颜色字符串，可能为nil
@property (nonatomic, copy) NSString *cancelColor;
/// 确认按钮的文字，最多 4 个字符， 可能为nil
@property (nonatomic, copy) NSString *confirmText;
/// 确认按钮的文字颜色，必须是 16 进制格式的颜色字符串， 可能为nil
@property (nonatomic, copy) NSString *confirmColor;
/// 是否显示取消按钮 默认是NO
@property (nonatomic, assign) BOOL showCancel;

@end

NS_ASSUME_NONNULL_END
