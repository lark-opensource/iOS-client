//
//  OPPluginFileCopy.m
//  OPPluginBiz
//
//  Created by yin on 2018/9/4.
//

#import "OPPluginFileCopy.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOProbe/ECOProbe-Swift.h>
#import <OPFoundation/BDPLocalFileConst.h>
#import <OPFoundation/EMAProtocolDefine.h>

@implementation OPPluginFileCopy

#pragma mark 选择附件

/// 新版API适配
/**
 将文件copy到应用文件夹下并生成临时目录

 @param sourcePath 文件原路径
 @param uniqueID 应用ID
 @return 生成好的临时路径
 */
+ (NSString *)copyFileFromPath:(NSString *)sourcePath uniqueID:(BDPUniqueID *)uniqueID {
    if ([LSFileSystem fileExistsWithFilePath:sourcePath isDirectory:nil]) {
        /// 注意：filepicker 有 copyFileFromPath 与 copyFileFromUrl 两套逻辑。
            OPFileObject *fileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp
                                                         fileExtension:sourcePath.pathExtension];
            OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:uniqueID
                                                                                   trace:nil
                                                                                     tag:@"filePicker"];
            NSError *error = nil;
            BOOL success = [OPFileSystemCompatible copySystemFile:sourcePath to:fileObj context:fsContext error:&error];
            if (!success || error) {
                fsContext.trace.error(@"filePicker copy system file error, success: %@, error: %@", @(success), error.description);
                return nil;
            }
            return fileObj.rawValue;
    }
    return nil;
}

/**
 将文件copy到应用文件夹下并生成临时目录

 @param sourcePath 文件原路径
 @param url 文件原路径
 @param uniqueID 应用ID
 @return 包含文件大小，路径和名称的字典
 */
+ (NSDictionary *)copyFileFromUrl:(NSURL *)url uniqueID:(BDPUniqueID *)uniqueID {
    if (!url) {
        return nil;
    }

    NSError *error = nil;
    OPFileObject *randomFileObj = [OPFileObject generateRandomTTFile:BDPFolderPathTypeTemp fileExtension:url.pathExtension];
    OPFileSystemContext *fsContext = [[OPFileSystemContext alloc] initWithUniqueId:uniqueID trace:nil tag:@"filePicker"];
    BOOL result = [OPFileSystemCompatible copySystemFile:url.path to:randomFileObj context:fsContext error:&error];
    if (!result || error) {
        fsContext.trace.error(@"copySystemFile faild, result: %@, error: %@", @(result), error.description);
        return nil;
    }

    error = nil;
    NSDictionary *attributes = [OPFileSystem attributesOfFile:randomFileObj context:fsContext error:&error];
    if (error) {
        fsContext.trace.error(@"get arributesOfFile faild, hasAttributes: %@, error: %@", @(attributes != nil), error.description);
    }
    unsigned long long size = [attributes fileSize];
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:3];
    [ret setObject:randomFileObj.rawValue forKey:kEMASDKFilePickerPath];
    NSString *nameStr = url.lastPathComponent;
    if (!BDPIsEmptyString(nameStr)) {
        [ret setValue:nameStr forKey:kEMASDKFilePickerName];
    }
    [ret setObject:@(size).stringValue forKey:kEMASDKFilePickerSize];
    return ret;
}

@end
