//
//  IESGurdFilePaths+InternalPackage.h
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/9/21.
//

#import "IESGurdFilePaths.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdFilePaths (InternalPackage)

+ (NSString *)internalPackagesDirectory;

+ (NSString *)internalPackageMetaInfosPath;

+ (NSString *)configFilePathWithBundleName:(NSString * _Nullable)bundleName;

+ (NSString *)bundlePathWithName:(NSString * _Nullable)bundleName;

+ (NSString *)internalPackageDirectoryForAccessKey:(NSString *)accessKey;

+ (NSString *)internalRootDirectoryForAccessKey:(NSString *)accessKey channel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
