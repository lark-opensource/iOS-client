//
//  BDPToastPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDPBaseJSONModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPToastPluginModel : BDPBaseJSONModel

/// 提示的内容
@property (nonatomic, copy) NSString *title;
/// 图标， 默认是nil，有 'success', 'loading'，'none' 三种
@property (nonatomic, copy) NSString *icon;
/// 自定义图标的本地路径，image 的优先级高于 icon 默认是nil
@property (nonatomic, copy) NSString *image;
/// 提示的延迟时间, 单位是毫秒，0表示不延迟
@property (nonatomic, assign) NSInteger duration;
/// 是否显示透明蒙层，防止触摸穿透, 默认是NO
@property (nonatomic, assign) BOOL mask;

@end

NS_ASSUME_NONNULL_END
