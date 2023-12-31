//
//  CJPayAIEnginePluginImpl.h
//  Aweme
//
//  Created by ByteDance on 2023/5/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAIEnginePluginImpl : NSObject
+ (instancetype)shareInstance;
- (void)setup;
- (NSDictionary *)getOutputForBusiness:(NSString *)business;
@end

NS_ASSUME_NONNULL_END
