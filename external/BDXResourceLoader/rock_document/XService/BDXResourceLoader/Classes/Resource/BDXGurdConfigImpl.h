//
//  BDXDefaultGurdConfigDelegate.h
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import <Foundation/Foundation.h>
#import "BDXGurdConfigDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXGurdConfigImpl : NSObject <BDXGurdConfigDelegate>

@property(nonatomic, copy) NSString *accessKeyName;
@property(nonatomic, copy) NSString *platformDomainName;

@end

NS_ASSUME_NONNULL_END
