//
//  ECOConfigKeys.h
//  ECOInfra
//
//  Created by  窦坚 on 2021/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于configKeys 的注册
@interface ECOConfigKeys : NSObject

@property (class, nonatomic, readonly) NSArray<NSString *> *allRegistedKeys;

+ (void)registerConfigKeys:(NSArray<NSString *> *) keys;

@end

@interface ECOConfigFetchContext: NSObject

@property (nonatomic) NSDictionary<NSString *, NSString *> *settingsConfig;

/// 异常流是否中断更新
@property (assign) BOOL shouldBreakUpdate;

- (instancetype)init NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
