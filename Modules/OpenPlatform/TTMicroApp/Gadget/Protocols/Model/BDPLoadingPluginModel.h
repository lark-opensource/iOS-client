//
//  BDPLoadingPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 显示loading信息模型
 */
@interface BDPLoadingPluginModel : BDPBaseJSONModel

/// 提示的内容
@property (nonatomic, copy) NSString *title;
/// 是否显示透明蒙层，防止触摸穿透 默认是 NO
@property (nonatomic, assign) BOOL mask;

@end

NS_ASSUME_NONNULL_END
