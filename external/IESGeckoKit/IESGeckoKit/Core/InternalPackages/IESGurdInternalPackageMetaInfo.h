//
//  IESGurdInternalPackageMetaInfo.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/17.
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdInternalPackageMetaInfo : NSObject <NSSecureCoding>

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, assign) uint64_t packageId;

@property (nonatomic, copy) NSString *bundleName;

@end

NS_ASSUME_NONNULL_END
