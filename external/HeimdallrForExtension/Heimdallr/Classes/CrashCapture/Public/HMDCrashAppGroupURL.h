//
//  HMDCrashAppGroupURL.h
//  Pods
//
//  Created by xuminghao.eric on 2020/8/17.
//

#import <Foundation/Foundation.h>


@interface HMDCrashAppGroupURL : NSObject

+ (NSURL * _Nullable)appGroupRootURL;
+ (NSURL * _Nullable)appGroupHeimdallrRootURL;
+ (NSURL * _Nullable)appGroupCrashSettingsURL;
+ (NSURL * _Nullable)appGroupCrashFilesURL;

@end

