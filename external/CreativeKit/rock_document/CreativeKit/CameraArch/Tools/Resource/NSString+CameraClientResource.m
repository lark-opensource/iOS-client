//
//  NSString+CameraClientResource.m
//  CameraClient
//
//  Created by Liu Deping on 2019/11/14.
//

#import "NSString+CameraClientResource.h"
#import "ACCResourceUnion.h"
#import "ACCMacros.h"
#import "ACCLanguageProtocol.h"
#import <IESLiveResourcesButler/IESLiveResourceBundle+File.h>
#import <IESLiveResourcesButler/IESLiveResouceBundle+KeyValue.h>

NSString *ACCResourceFile(NSString *name)
{
    return [NSString acc_filePathWithName:name];
}

@implementation NSString (CameraClientResource)

+ (NSString *)acc_strValueWithName:(NSString *)name
{
    NSString *str = (NSString *)ACCResourceUnion.cameraResourceBundle.value(name);
    str = ACCLocalizedCurrentString(str);
    return str ? : @"";
}

+ (NSString *)acc_filePathWithName:(NSString *)fileName
{
    NSString *filePath = ACCResourceUnion.cameraResourceBundle.filePath(fileName);
    NSAssert(filePath != nil, @"CameraClient does not find fileName:%@", fileName);
    return filePath;
}

+ (NSString *)acc_filePathWithName:(NSString *)fileName inDirectory:(NSString *)directory
{
    NSString *filePath = ACCResourceUnion.cameraResourceBundle.filePathInfolder(fileName, directory);
    
    NSAssert(filePath != nil, @"CameraClient does not find fileName:%@", fileName);
    return filePath;
}

+ (NSString *)acc_configInfoWithName:(NSString *)name
{
    return (NSString *)ACCResourceUnion.cameraResourceBundle.config(name);
}

+ (NSString *)acc_bundlePathWithName:(NSString *)name
{
    NSString *bundlePath = nil;
    bundlePath = ACCResourceUnion.cameraResourceBundle.bundlePath(name);
    NSAssert(bundlePath, @"%s There is no file exist, please check bundle name:%@", __PRETTY_FUNCTION__, name);
    return bundlePath;
}

@end
