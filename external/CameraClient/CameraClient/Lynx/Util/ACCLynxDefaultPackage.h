//
//  ACCLynxDefaultPackage.h
//  CameraClient-Pods-AwemeCore-CameraResource_douyin
//
//  Created by wanghongyu on 2021/10/21.
//

#import <Foundation/Foundation.h>

@protocol ACCLynxDefaultPackageTemplate;
@class ACCLynxDefaultPackageLoadModel;

@interface ACCLynxDefaultPackage : NSObject

+ (void)loadDefaultPackageModel:(nonnull ACCLynxDefaultPackageLoadModel *)model;

@end

