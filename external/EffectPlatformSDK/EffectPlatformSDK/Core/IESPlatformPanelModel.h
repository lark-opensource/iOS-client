//
//  IESPlatformPanelModel.h
//  EffectPlatformSDK
//
//  Created by leizh007 on 2018/3/22.
//

#import <Foundation/Foundation.h>
#import "IESEffectDefines.h"
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

// 面板信息
@interface IESPlatformPanelModel : MTLModel<MTLJSONSerializing>

// 面板文案
@property(nonatomic, readonly, copy) NSString *text;

// 面板图标
@property(nonatomic, readonly, copy) NSArray<NSString *> *iconURLs;

// 面板图标
@property(nonatomic, readonly, copy) NSString *iconURI;

// 标签值
@property(nonatomic, readonly, copy) NSArray<NSString *> *tags;

// 标签更新时间
@property(nonatomic, readonly, copy) NSString *tagsUpdatedTimeStamp;

// 存放额外的业务信息，自定义字段：json字符串
@property(nonatomic, readonly, copy, nullable) NSString *extra;

@end

NS_ASSUME_NONNULL_END
