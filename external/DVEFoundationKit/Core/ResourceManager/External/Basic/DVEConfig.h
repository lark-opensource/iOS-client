//
//  DVEConfig.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 用于提取 config.json 中注入的信息
@interface DVEConfig : NSObject

@property (nonatomic, assign) BOOL enable;

+ (BOOL)dve_boolValueWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
