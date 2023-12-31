//
//  NSURL+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import <Foundation/Foundation.h>

@interface NSURL (EMA)

- (NSDictionary *)ema_queryItems;

/// 工具方法，从 NSURL 解析参数
-(NSString *)ema_paramForKey:(NSString *)key;

@end

