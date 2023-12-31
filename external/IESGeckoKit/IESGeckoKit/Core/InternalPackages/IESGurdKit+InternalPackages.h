//
//  IESGurdKit+InternalPackages.h
//  BDAssert
//
//  Created by 陈煜钏 on 2020/9/16.
//

#import "IESGeckoKit.h"

NS_ASSUME_NONNULL_BEGIN

/// 1. 内置包资源文件必须放在某个bundle下，并且有一份配置文件描述相关信息，配置文件命名为：gecko_internal_packages.json
/// 2. 内置包支持zip包和单文件，文件类型在配置文件中描述
/// 3. 内置包会被解压或复制到 Gurd 内部文件目录下，并记录相关元信息；当发现没有配置文件，或配置文件内没有某个channel时，会清理内部对应的资源文件

@interface IESGurdKit (InternalPackages)

+ (void)activeAllInternalPackagesInMainBundleWithCompletion:(void (^)(BOOL succeed))completion;

+ (void)activeAllInternalPackagesWithBundleName:(NSString * _Nullable)bundleName
                                     completion:(void (^)(BOOL succeed))completion;

+ (void)activeInternalPackageInMainBundleWithAccessKey:(NSString *)accessKey
                                               channel:(NSString *)channel
                                            completion:(void (^)(BOOL succeed))completion;

+ (void)activeInternalPackageWithBundleName:(NSString * _Nullable)bundleName
                                  accessKey:(NSString *)accessKey
                                    channel:(NSString *)channel
                                 completion:(void (^)(BOOL succeed))completion;

+ (void)clearInternalPackageForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

+ (NSString *)internalRootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
