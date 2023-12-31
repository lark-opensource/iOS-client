//
//  ACCLynxDefaultPackageLoadModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by wanghongyu on 2021/10/22.
//

#import <Foundation/Foundation.h>

@interface ACCLynxDefaultPackageLoadModel : NSObject

@property (nonatomic, copy, nonnull) NSString *localResourcePath;
@property (nonatomic, copy, nonnull) NSString *gurdFilePath;
@property (nonatomic, copy, nonnull) NSString *gurdRootDir;
@property (nonatomic, assign) BOOL needUnzip;

@end
