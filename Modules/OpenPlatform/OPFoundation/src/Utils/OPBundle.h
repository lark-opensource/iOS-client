//
//  OPBundle.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/8.
//

#import <Foundation/Foundation.h>

@interface OPBundle : NSObject

+ (NSBundle *)bundle;

// 检查指定class所在的framework里的指定bundle/mainBundle
+ (NSBundle *)bundleWithName:(NSString *)bundleName inFramework:(NSString *)framworkClassName;

@end
