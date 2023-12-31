//
//  EMASandBoxHelper.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import <Foundation/Foundation.h>

@interface EMASandBoxHelper : NSObject

@end


@interface EMASandBoxHelper (EMAPlist)

/**
 *  获取info.plist中的CFBundleDisplayName
 *
 *  @return 如果没有，返回CFBundleName
 */
+ (nullable NSString *)appDisplayName;

/**
 *  获取info.plist发布版本号
 *
 *  @return 可能为nil
 */
+ (nullable NSString *)versionName;

/**
 *  获取plist中的CFBundleIdentifier
 *
 *  @return CFBundleIdentifier
 */
+ (nullable NSString*)bundleIdentifier;

/**
 *  获取plist中的CFBundleVersion
 *
 *  @return CFBundleVersion
 */
+ (nonnull NSString *)buildVerion;

/**
 *  获取info.plist中的App Name
 *
 *  @return 可能为nil
 */
+ (nullable NSString *)appName;


/**
 * 获取info.plist中的 GADGET_DEBUG 字段值
 *
 * @return 如果没有该字段返回 NO，否则按照字段配置
 */
+ (BOOL)gadgetDebug;

@end
