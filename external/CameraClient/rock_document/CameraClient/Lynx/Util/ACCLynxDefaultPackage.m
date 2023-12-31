//
//  ACCLynxDefaultPackage.m
//  CameraClient-Pods-AwemeCore-CameraResource_douyin
//
//  Created by wanghongyu on 2021/10/21.
//

#import "ACCLynxDefaultPackage.h"
#import <SSZipArchive/SSZipArchive.h>
#import <CreationKitInfra/ACCLogHelper.h>

#import "ACCLynxDefaultPackageTemplate.h"
#import "ACCLynxDefaultPackageLoadModel.h"


@implementation ACCLynxDefaultPackage

+ (void)loadDefaultPackageModel:(ACCLynxDefaultPackageLoadModel *)model {
    NSString *fromPath = model.localResourcePath;
    NSString *toPath = model.gurdFilePath;
    NSString *gurdRootDir = model.gurdRootDir;

    BOOL needUnzip = model.needUnzip;

    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL fromFileExist = [manager fileExistsAtPath:fromPath];
    BOOL toFileExist = [manager fileExistsAtPath:toPath];

    if (!fromFileExist) {
        return;
    }

    NSError *fileError;
    if (!toFileExist) {
        if (needUnzip) {
            [SSZipArchive unzipFileAtPath:fromPath toDestination:gurdRootDir overwrite:NO password:nil error:&fileError];
        } else {
            [manager copyItemAtPath:fromPath toPath:gurdRootDir error:&fileError];
        }
    }
    
    AWELogToolError(AWELogToolTagRecord, @"%s %@", __PRETTY_FUNCTION__, fileError);
    NSCAssert(fileError == nil, @"Cameraclient gurd inner package load fail from: %@, to: %@", fromPath, toPath);
}


@end
