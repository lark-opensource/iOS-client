//
//  BDPAuthorization+Schema.h
//  Timor
//
//  Created by liuxiangxin on 2019/12/10.
//

#import <UIKit/UIKit.h>
#import "BDPAuthorization.h"
#import "BDPUniqueID.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPAuthorization (BDPSchema)

- (NSArray *)domainsListWithAuthType:(BDPAuthorizationURLDomainType)authType;

- (NSArray *)defaultSchemaSupportList;

- (NSArray *)webViewComponentSpecialSchemaSupportList;

- (BOOL)checkAuthorizationURL:(NSString *)url authType:(BDPAuthorizationURLDomainType)authType;

/// 调用openSchema时检测url是否可被打开
- (BOOL)checkSchema:(NSURL **)url uniqueID:(BDPUniqueID *)uniqueID errorMsg:(NSString **)errorMsg;

@end

NS_ASSUME_NONNULL_END
