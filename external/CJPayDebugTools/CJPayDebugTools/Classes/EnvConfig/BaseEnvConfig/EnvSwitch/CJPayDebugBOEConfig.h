//
//  CJPayDebugBOEConfig.h
//  CJPay
//
//  Created by wangxiaohong on 2020/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDebugBOEConfig : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL boeIsOpen;

// boe 相关配置, 如果不配置会使用默认值
@property (nonatomic, copy) NSString *boeSuffix;
@property (nonatomic, copy) NSArray *boeWhiteList;
@property (nonatomic, copy) NSDictionary *boeEnv;
@property (nonatomic, copy) NSString *configHost;

// 开启和关闭Boe
- (void)enableBoe;
- (void)disableBoe;
// 更新boe的环境的cookie
- (void)updateBoeCookies;

@end

NS_ASSUME_NONNULL_END
