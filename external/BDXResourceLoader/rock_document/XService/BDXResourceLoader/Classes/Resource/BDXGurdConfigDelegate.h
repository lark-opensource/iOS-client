//
//  BDXGurdConfigDelegate.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>

#ifndef BDXGurdConfigDelegate_h
#define BDXGurdConfigDelegate_h

@protocol BDXGurdConfigDelegate <NSObject>

- (NSString *)accessKey;

- (BOOL)isNetworkDelegateEnabled;

- (BOOL)isBusinessDomainEnabled;

- (NSString *)platformDomain;

@end

#endif /* BDXGurdConfigDelegate_h */
