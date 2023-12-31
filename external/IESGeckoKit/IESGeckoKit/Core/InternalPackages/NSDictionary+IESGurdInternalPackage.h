//
//  NSDictionary+IESGurdInternalPackage.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/9/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kIESGurdInternalPackageConfigKeyAccessKey;
extern NSString * const kIESGurdInternalPackageConfigKeyChannel;

@interface NSDictionary (IESGurdInternalPackage)

+ (NSDictionary *)gurd_configDictionaryWithBundleName:(NSString *)bundleName;

@end

NS_ASSUME_NONNULL_END
