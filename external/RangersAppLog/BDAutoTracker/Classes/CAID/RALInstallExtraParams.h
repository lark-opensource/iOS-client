//
//  BDInstallExtraParams.h
//  BDInstall
//
//  Created by han yang on 2020/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RALInstallExtraParams : NSObject

+ (NSDictionary <NSString *, NSObject *> *)extraIDsWithAppID:(NSString *)appID;

+ (NSDictionary <NSString *, NSObject *> *)extraDeviceParams;

@end

NS_ASSUME_NONNULL_END
