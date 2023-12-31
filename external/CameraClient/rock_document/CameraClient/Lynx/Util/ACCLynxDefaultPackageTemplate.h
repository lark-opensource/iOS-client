//
//  ACCLynxDefaultPackageTemplate.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/22.
//

#import <Foundation/Foundation.h>

@class ACCLynxDefaultPackageLoadModel;
@protocol ACCLynxDefaultPackageTemplate <NSObject>
- (NSArray<ACCLynxDefaultPackageLoadModel *> *)templates;
@end

