//
//  VLChannelJsonUtil.h
//  Runner
//
//  Created by bytedance on 2020/4/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 将data转换为NSDictionary类型的数据
/// 因为data可能为自定义model需要借助YYModel进行字典转换
/// YYModel中会将NSData类型以及FlutterStandardTypedData我们需要类型进行过滤
/// 所以需要进行相关的内置处理
@interface BDChannelJsonUtil : NSObject

+ (id)parseToJsonObject:(id)data;

@end

NS_ASSUME_NONNULL_END
