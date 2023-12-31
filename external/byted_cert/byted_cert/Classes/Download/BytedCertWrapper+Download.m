//
//  BytedCertWrapper+Download.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/10.
//

#import "BytedCertWrapper+Download.h"
#import "BDCTEventTracker.h"
#import "BDCTEventTracker+Offline.h"
#import "BDCTStringConst.h"
#import "BytedCertDefine.h"
#import "BytedCertManager+Private.h"
#import "BytedCertManager+DownloadPrivate.h"
#import "BytedCertInterface+Logger.h"

#import <IESGeckoKit/IESGeckoKit.h>
#import <objc/runtime.h>
#import <BDAssert/BDAssert.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>

NSString *const GECKO_ACCESS_KEY = @"5c7ee26b59edea148ed605d013fd23bb";
NSString *const GECKO_ACCESS_KEY_BOE = @"da1c417cd04a3b2af8e8ff0fcbff816a";
NSString *const GECKO_GROUP_TYPE = @"default";


@implementation BytedCertWrapper (Download)

- (NSString *)geckoAccessKey {
    return BytedCertManager.isBoe ? GECKO_ACCESS_KEY_BOE : GECKO_ACCESS_KEY;
}

- (NSMutableSet *)geckoChannelList {
    NSMutableSet *geckoChannelList = objc_getAssociatedObject(self, _cmd);
    if (!geckoChannelList) {
        geckoChannelList = [NSMutableSet set];
        objc_setAssociatedObject(self, _cmd, geckoChannelList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return geckoChannelList;
}

- (NSString *)appId {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAppId:(NSString *)appId {
    objc_setAssociatedObject(self, @selector(appId), appId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)appVersion {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAppVersion:(NSString *)appVersion {
    objc_setAssociatedObject(self, @selector(appVersion), appVersion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)mDownloadPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMDownloadPath:(NSString *)mDownloadPath {
    objc_setAssociatedObject(self, @selector(mDownloadPath), mDownloadPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)mDeviceId {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMDeviceId:(NSString *)mDeviceId {
    objc_setAssociatedObject(self, @selector(mDeviceId), mDeviceId, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setPreloadParams:(NSDictionary *_Nullable)params {
    [self initDownloadParams:params];
}

- (void)checkLoadStatus:(BytedCertResultBlock)callback {
    int modelStatus = [self checkModelAvailable];
    if (modelStatus != 0) {
        BytedCertError *error = [[BytedCertError alloc] initWithType:modelStatus];
        callback(NO, error);
        return;
    } else {
        callback(YES, nil);
        return;
    }
}

- (void)preload:(BytedCertResultBlock)callback {
    [self preload:callback checkAfterLoad:NO];
}

- (void)checkAndPreload:(BytedCertResultBlock)callback {
    [self preload:callback checkAfterLoad:YES];
}

- (void)preload:(BytedCertResultBlock)callback checkAfterLoad:(BOOL)checkAvailable {
    [BDCTEventTracker trackcertModelPreloadStartEvent];

    int modelStatus = [self checkModelAvailable];
    if (modelStatus != 0) {
        [self geckoUpdate:^(BOOL succeed, IESGurdSyncStatusDict _Nonnull dict) {
            [BDCTEventTracker trackCertModelPreloadEventWithResult:(succeed ? (dict ? 1 : 2) : 0) errorMsg:nil];
            if (succeed) {
                BytedCertError *error = nil;
                for (NSString *channel in self.geckoChannelList) {
                    if ([dict[channel] intValue] == IESGurdSyncStatusServerPackageUnavailable)
                        error = [[BytedCertError alloc] initWithType:BytedCertErrorNoUpdateModel];
                }
                if (checkAvailable) {
                    [self checkLoadStatus:callback];
                } else {
                    callback(YES, error);
                }
            } else {
                BytedCertError *error = [[BytedCertError alloc] initWithType:BytedCertErrorUpdateModelFailure];
                callback(NO, error);
            }
        }
            eventDelegate:nil];
    } else {
        callback(YES, nil);
    }
}

- (void)initDownloadParams:(NSDictionary *_Nullable)params {
    //init params
    self.appId = params[BytedCertParamAppId];
    self.appVersion = params[BytedCertParamAppVersion];
    self.mDownloadPath = params[BytedCertParamCacheRootDirectory];
    BDAssert(self.mDownloadPath.length, @"模型保存路径不能为空");

    if (params[BytedCertParamTargetReflection] != nil)
        [self.geckoChannelList addObject:BytedCertParamTargetReflection];
    if (params[BytedCertParamTargetOffline] != nil)
        [self.geckoChannelList addObject:BytedCertParamTargetOffline];
    if (params[BytedCertParamTargetAudio] != nil)
        [self.geckoChannelList addObject:BytedCertParamTargetAudio];
    self.mDeviceId = params[BytedCertParamDeviceId];
    [BytedCertInterface logWithInfo:@"gurd donwload params init" params:params];
    //set cacheRootDirectory first
    [IESGurdKit setupWithAppId:self.appId
                    appVersion:self.appVersion
            cacheRootDirectory:self.mDownloadPath];
}

- (void)geckoUpdate:(IESGurdSyncStatusDictionaryBlock)completion eventDelegate:(id<IESGurdEventDelegate>)delegate {
    [IESGurdKit registerAccessKey:[self geckoAccessKey]];

    if (self.mDeviceId != nil) {
        IESGurdKit.deviceID = self.mDeviceId;
    } else {
        BDAssert(self.mDeviceId, @"DeviceId must not be nil.");
        IESGurdKit.deviceID = BDTrackerProtocol.deviceID;
    }

    [IESGurdKit registerEventDelegate:delegate];

    [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams *_Nonnull params) {
        params.accessKey = [self geckoAccessKey];
        params.channels = [self.geckoChannelList allObjects];
        //        params.customParams = @{ IESGurdCustomParamKeyBusinessVersion: sdkVersion };
        params.resourceVersion = BytedCertSDKVersion;
        params.disableThrottle = YES;
    } completion:completion];
}

- (int)checkModelAvailable {
    int ret;
    if ([self.geckoChannelList containsObject:BytedCertParamTargetOffline]) {
        ret = [self checkChannelAvailable:bdct_offline_model_pre() channel:BytedCertParamTargetOffline];
        BytedCertError *error = [[BytedCertError alloc] initWithType:ret];
        [BDCTEventTracker trackLocalModelAvailable:BytedCertParamTargetOffline error:error];
        if (ret != 0) {
            return ret;
        }
    }

    if ([self.geckoChannelList containsObject:BytedCertParamTargetReflection]) {
        ret = [self checkChannelAvailable:bdct_reflection_model_pre() channel:BytedCertParamTargetReflection];
        BytedCertError *error = [[BytedCertError alloc] initWithType:ret];
        [BDCTEventTracker trackLocalModelAvailable:BytedCertParamTargetReflection error:error];
        if (ret != 0) {
            return ret;
        }
    }

    if ([self.geckoChannelList containsObject:BytedCertParamTargetAudio]) {
        ret = [self checkChannelAvailable:bdct_audio_resource_pre() channel:BytedCertParamTargetAudio checkMd5:NO];
        if (ret != 0) {
            return ret;
        }
    }

    return 0;
}

- (int)checkModelAvailable:(NSArray *)modelPre path:(NSString *)channel {
    return [self checkChannelAvailable:modelPre channel:channel];
}

- (int)checkChannelAvailable:(NSArray *)filePre channel:(NSString *)channel {
    return [self checkChannelAvailable:filePre channel:channel checkMd5:YES];
}

- (int)checkChannelAvailable:(NSArray *)filePre channel:(NSString *)channel checkMd5:(BOOL)checkMd5 {
    //check has download
    NSString *modelPath;
    if (self.modelPathList[channel] == nil) {
        self.modelPathList[channel] = [IESGurdKit rootDirForAccessKey:[self geckoAccessKey] channel:channel];
    }
    modelPath = self.modelPathList[channel];
    if (modelPath == nil) {
        [BytedCertInterface logWithErrorInfo:@"byted_cert check model fail: model path not exist" params:@{@"channel" : channel} error:nil];
        return BytedCertErrorNoDownload;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = FALSE;
    BOOL isDirExist = [fileManager fileExistsAtPath:modelPath isDirectory:&isDir];
    if (!(isDirExist && isDir)) {
        [BytedCertInterface logWithErrorInfo:@"byted_cert check model fail: dir int model path not exist" params:@{@"channel" : channel} error:nil];
        return BytedCertErrorNoDownload;
    }
    NSString *suffix = @"model";
    if ([channel isEqualToString:BytedCertParamTargetAudio]) {
        suffix = @"mp3";
    }
    for (NSString *pre in filePre) {
        NSString *res = [BytedCertManager getResourceByPath:modelPath pre:pre suffix:suffix];
        if (res == nil) {
            [self clearCache];
            [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cert check model fail: model resource %@ not exist", res] params:@{@"channel" : channel} error:nil];
            return BytedCertErrorNoModel;
        }
        if (checkMd5) {
            NSString *md5File = [NSString stringWithFormat:@"%@.txt", res];
            isDirExist = [fileManager fileExistsAtPath:md5File isDirectory:&isDir];
            if (!isDirExist) {
                [self clearCache];
                [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cert check model fail: model resource %@  md5 file not exist", res] params:@{@"channel" : channel} error:nil];
                return BytedCertErrorModelMd5;
            }
            NSString *md5 = [NSString stringWithContentsOfFile:md5File encoding:NSUTF8StringEncoding error:nil];
            if (![BytedCertManager checkMd5:res md5:md5]) {
                [self clearCache];
                [BytedCertInterface logWithErrorInfo:[NSString stringWithFormat:@"byted_cert check model fail: %@ md5 check fail", res] params:@{@"channel" : channel} error:nil];
                return BytedCertErrorModelMd5;
            }
        }
    }

    return 0;
}


- (int)checkResourceStatusWithChannel:(NSString *)channel {
    if ([channel isEqualToString:BytedCertParamTargetOffline] || [channel isEqualToString:BytedCertParamTargetReflection]) {
        return [self checkModelAvailable];
    }
    if ([channel isEqualToString:BytedCertParamTargetAudio]) {
        return [self checkChannelAvailable:bdct_audio_resource_pre() channel:BytedCertParamTargetAudio checkMd5:NO];
    }
    return -1;
}

- (void)geckoDownloadAudioResource:(void (^)(BOOL success, NSDictionary *_Nullable downLoadResultDic, NSString *_Nullable path))callback {
    int resourceStatus = [self checkResourceStatusWithChannel:BytedCertParamTargetAudio];
    if (resourceStatus != 0) {
        __block BOOL isCompleted = NO;
        void (^completion)(BOOL, NSDictionary *_Nullable, NSString *_Nullable) = ^(BOOL success, NSDictionary *_Nullable downLoadResultDic, NSString *_Nullable path) {
            if (isCompleted) {
                return;
            }
            isCompleted = YES;
            !callback ?: callback(success, downLoadResultDic, path);
        };
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableDictionary *downLoadResultDic = [[NSMutableDictionary alloc] init];
            downLoadResultDic[@"error_code"] = @(BytedCertErrorUpdateModelFailure);
            downLoadResultDic[@"gurd_status_code"] = @(IESGurdSyncStatusFailed);
            completion(NO, downLoadResultDic, nil);
        });
        IESGurdKit.deviceID = BDTrackerProtocol.deviceID;
        [IESGurdKit registerAccessKey:[self geckoAccessKey]];
        [IESGurdKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams *_Nonnull params) {
            params.accessKey = [self geckoAccessKey];
            params.channels = [NSArray arrayWithObject:BytedCertParamTargetAudio];
            params.resourceVersion = BytedCertSDKVersion;
            params.disableThrottle = YES;
        } completion:^(BOOL succeed, IESGurdSyncStatusDict _Nonnull dict) {
            [BDCTEventTracker trackCertModelPreloadEventWithResult:(succeed ? (dict ? 1 : 2) : 0) errorMsg:nil];
            if (succeed) {
                int resourceDownloadStatus = [self checkResourceStatusWithChannel:BytedCertParamTargetAudio];
                NSMutableDictionary *downLoadResultDic = nil;
                if (resourceDownloadStatus != 0) {
                    downLoadResultDic = [[NSMutableDictionary alloc] init];
                    downLoadResultDic[@"error_code"] = @(resourceDownloadStatus);
                    downLoadResultDic[@"gurd_status_code"] = dict[BytedCertParamTargetAudio];
                }
                completion(resourceDownloadStatus == 0, downLoadResultDic, [IESGurdKit rootDirForAccessKey:[self geckoAccessKey] channel:BytedCertParamTargetAudio]);
            } else {
                NSMutableDictionary *downLoadResultDic = [[NSMutableDictionary alloc] init];
                downLoadResultDic[@"error_code"] = @(BytedCertErrorUpdateModelFailure);
                downLoadResultDic[@"gurd_status_code"] = dict[BytedCertParamTargetAudio];
                completion(NO, downLoadResultDic, nil);
            }
        }];
    } else {
        callback(YES, nil, [IESGurdKit rootDirForAccessKey:[self geckoAccessKey] channel:BytedCertParamTargetAudio]);
    }
}


- (void)clearCache {
    for (NSString *channel in self.geckoChannelList) {
        [IESGurdKit clearCacheForAccessKey:[self geckoAccessKey] channel:channel];
    }
}

@end
