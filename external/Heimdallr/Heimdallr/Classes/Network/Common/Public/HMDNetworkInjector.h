//
//  HMDNetworkInjector.h
//  Heimdallr
//
//  Created by fengyadong on 2021/5/18.
//

#import <Foundation/Foundation.h>

typedef NSData * _Nullable (^ _Nullable HMDNetEncryptBlock)(NSData * _Nullable);

@interface HMDNetworkInjector : NSObject

+ (nonnull instancetype)sharedInstance;

- (void)configEncryptBlock:(HMDNetEncryptBlock _Nullable)encryptBlock;
- (HMDNetEncryptBlock _Nullable)encryptBlock;

@end
