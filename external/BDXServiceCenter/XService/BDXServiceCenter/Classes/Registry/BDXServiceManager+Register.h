//
//  BDXServiceManager+Register.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/2.
//

#import "BDXServiceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXServiceManager (Register)

+ (NSArray<NSString *> *)bdxservice_autoRegisteredService;

- (void)bdx_autoRegisterService;

@end

NS_ASSUME_NONNULL_END
