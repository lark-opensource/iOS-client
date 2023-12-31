//
//  BDPPackageCardInstaller.m
//  Timor
//
//  Created by houjihu on 2020/5/25.
//

#import "BDPPackageCardInstaller.h"
#import <ECOInfra/BDPLog.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPPackageCardProjectConfigModel.h"
#import <ECOInfra/BDPFileSystemHelper.h>
#import <LarkStorage/LarkStorage-Swift.h>
#import <OPFoundation/NSError+BDPExtension.h>

@implementation BDPPackageCardInstaller

+ (BOOL)installWithPackageDirectoryPath:(NSString *)packageDirectoryPath error:(NSError **)error {
    // 读取project.config.json，获取entry入口所在目录，即为需要安装的代码文件
    NSError *getCardPackageDirectoryError;
    NSString *cardPackageDirectory = [self getCardPackageDirectoryFromPackageDirectoryPath:packageDirectoryPath error:&getCardPackageDirectoryError];
    if (getCardPackageDirectoryError) {
        if (error) {
            *error = getCardPackageDirectoryError;
        }
        return NO;
    }
    NSError *contentsFetchError;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contentsToMove = [fileManager contentsOfDirectoryAtPath:cardPackageDirectory error:&contentsFetchError];
    if (contentsFetchError) {
        contentsFetchError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, contentsFetchError, BDPParamStr(packageDirectoryPath, cardPackageDirectory));
        if (error) {
            *error = contentsFetchError;
        }
        return NO;
    }
    // 安装之前，先记录包安装目录里的文件，即为安装后需要删除的文件
    NSArray<NSString *> *contentsToDelete = [fileManager contentsOfDirectoryAtPath:packageDirectoryPath error:&contentsFetchError];
    if (contentsFetchError) {
        contentsFetchError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, contentsFetchError, BDPParamStr(packageDirectoryPath));
        if (error) {
            *error = contentsFetchError;
        }
        return NO;
    }
    // 1) 移动卡片entry所在目录内的所有文件到包目录
    for (NSString *pathToMove in contentsToMove) {
        // 获得目标文件的上级目录
        NSString *toPath = [packageDirectoryPath stringByAppendingPathComponent:[pathToMove lastPathComponent]];
        NSString *toDirPath = [toPath stringByDeletingLastPathComponent];
        [BDPFileSystemHelper createFolderIfNeed:toDirPath];
        // 判断目标路径文件是否存在，如果存在则需要先删除
        if ([fileManager fileExistsAtPath:toPath]) {
            // 如果存在，则先删除目标路径文件
            NSError *removeError;
            NSString *removePath = toPath;
            BOOL removeSuccess = [fileManager removeItemAtPath:removePath error:&removeError];
            if (!removeSuccess) {
                removeError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, removeError, BDPParamStr(packageDirectoryPath, removePath));
                if (error) {
                    *error = removeError;
                }
                return NO;
            }
        }

        // 移动目标路径文件
        NSString *fromPath = [cardPackageDirectory stringByAppendingPathComponent:pathToMove];
        NSError *moveError;
        BOOL moveSuccess = [fileManager moveItemAtPath:fromPath toPath:toPath error:&moveError];
        if (!moveSuccess) {
            moveError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, moveError, BDPParamStr(fromPath, toPath, packageDirectoryPath));
            if (error) {
                *error = moveError;
            }
            return NO;
        }
    }
    // 2) 把之前记录的包目录的其他所有文件删除
    for (NSString *pathToRemove in contentsToDelete) {
        // 排除覆盖安装时之前代码包目录内已经存在需要安装的文件
        if ([contentsToMove containsObject:pathToRemove]) {
            continue;
        }
        NSString *removePath = [packageDirectoryPath stringByAppendingPathComponent:pathToRemove];
        NSError *removeError;
        BOOL removeSuccess = [fileManager removeItemAtPath:removePath error:&removeError];
        if (!removeSuccess) {
            removeError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_install_failed, removeError, BDPParamStr(packageDirectoryPath, removePath));
            if (error) {
                *error = removeError;
            }
            return NO;
        }
    }

    return YES;
}

/// 从下载的包目录中读取project.config.json，解析出model
+ (NSString *)getCardPackageDirectoryFromPackageDirectoryPath:(NSString * _Nonnull)packageDirectoryPath error:(NSError **)error {
    if (BDPIsEmptyString(packageDirectoryPath)) {
        NSString *errorMessage = @"packageDirectoryPath to install is empty";
        NSError *emptyPathError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_install_invalid_params, errorMessage);
        if (error) {
            *error = emptyPathError;
        }
        return nil;
    }
    NSString *projectConfigPath = [packageDirectoryPath stringByAppendingPathComponent:@"project.config.json"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:projectConfigPath]) {
        NSString *errorMessage = [NSString stringWithFormat:@"projectConfigPath(%@) to install is not exsit", projectConfigPath];
        NSError *noFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, errorMessage);
        if (error) {
            *error = noFileError;
        }
        return nil;
    }

    // 根据卡片包结构设计，需要取entry
    NSError *getEntryError;
    NSString *entry = [self getEntryFromProjectConfigPath:projectConfigPath error:&getEntryError];
    if (getEntryError) {
        if (error) {
            *error = getEntryError;
        }
        return nil;
    }
    // 取entry所在的目录，将此目录里的所有文件移动到包目录
    NSString *entryPath = [packageDirectoryPath stringByAppendingPathComponent:entry];
    if (![fileManager fileExistsAtPath:entryPath]) {
        NSString *errorMessage = [NSString stringWithFormat:@"card entry is not exsit: %@", entryPath];
        NSError *noFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_file_not_found, errorMessage);
        if (error) {
            *error = noFileError;
        }
        return nil;
    }
    // 移动卡片entry所在目录内的所有文件到包目录，并把包目录的其他所有文件删除
    NSString *cardPackageDirectory = [entryPath stringByDeletingLastPathComponent];
    return cardPackageDirectory;
}

/// 读取卡片工程配置，获取entry
+ (NSString *)getEntryFromProjectConfigPath:(NSString *)projectConfigPath error:(NSError **)error {
    // file -> data
    NSData* data = [NSData lss_dataWithContentsOfFile:projectConfigPath error: nil];
    if ([data length] == 0) {
        NSString *errorMessage = [NSString stringWithFormat:@"data of projectConfigPath(%@) to install is empty", projectConfigPath];
        NSError *noDataError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, errorMessage);
        if (error) {
            *error = noDataError;
        }
        return nil;
    }
    // data -> dict
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError || ![json isKindOfClass:[NSDictionary class]]) {
        jsonError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_read_data_failed, jsonError, BDPParamStr(projectConfigPath));
        if (error) {
            *error = jsonError;
        }
        return nil;
    }
    // dict -> model
    NSError *modelDecodeError;
    BDPPackageCardProjectConfigModel *projectConfig = [[BDPPackageCardProjectConfigModel alloc] initWithDictionary:json error:&modelDecodeError];
    if (modelDecodeError) {
        modelDecodeError = OPErrorWithErrorAndMsg(CommonMonitorCodePackage.pkg_read_data_failed, modelDecodeError, BDPParamStr(json));
        if (error) {
            *error = modelDecodeError;
        }
        return nil;
    }
    // 获取entry入口文件路径
    NSArray<BDPPackageCardConfigModel *> *cardConfigs = projectConfig.cardConfigs;
    if (cardConfigs.count == 0) {
        NSString *errorMessage = [NSString stringWithFormat:@"cardConfigs of projectConfigPath(%@) to install is empty", projectConfigPath];
        NSError *noFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, errorMessage);
        if (error) {
            *error = noFileError;
        }
        return nil;
    }
    BDPPackageCardConfigModel *cardConfig = cardConfigs.firstObject;
    if (BDPIsEmptyString(cardConfig.entry)) {
        NSString *errorMessage = [NSString stringWithFormat:@"card config error: cardID(%@), version(%@), entry(%@)", cardConfig.cardID, cardConfig.version, cardConfig.entry];
        NSError *noFileError = OPErrorWithMsg(CommonMonitorCodePackage.pkg_read_data_failed, errorMessage);
        if (error) {
            *error = noFileError;
        }
        return nil;
    }
    return cardConfig.entry;
}

@end
