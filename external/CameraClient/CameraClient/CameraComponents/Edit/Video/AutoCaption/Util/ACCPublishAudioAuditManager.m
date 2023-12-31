//
//  ACCPublishAudioAuditManager.m
//  AWEStudio-Pods-Aweme
//
//  Created by hellaflush on 2020/7/20.
//

#import "ACCPublishAudioAuditManager.h"
#import <CameraClient/ACCFileUploadServiceBuilder.h>
#import <CameraClient/ACCPublishNetServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/ACCAudioNetServiceProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>

#define ACCPublishAudioAuditTaskSELToStr(sel) NSStringFromSelector(@selector(sel))

@implementation ACCPublishAudioAuditTask
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.awemeId forKey:ACCPublishAudioAuditTaskSELToStr(awemeId)];
    [coder encodeDouble:self.createTimeInterval forKey:ACCPublishAudioAuditTaskSELToStr(createTimeInterval)];
    [coder encodeObject:self.audioFilePath forKey:ACCPublishAudioAuditTaskSELToStr(audioFilePath)];
    [coder encodeBool:self.useTmpPath forKey:ACCPublishAudioAuditTaskSELToStr(useTmpPath)];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    ACCPublishAudioAuditTask *task = [ACCPublishAudioAuditTask new];
    task.awemeId = [coder decodeObjectForKey:ACCPublishAudioAuditTaskSELToStr(awemeId)];
    task.createTimeInterval = [coder decodeDoubleForKey:ACCPublishAudioAuditTaskSELToStr(createTimeInterval)];
    task.audioFilePath = [coder decodeObjectForKey:ACCPublishAudioAuditTaskSELToStr(audioFilePath)];
    task.useTmpPath = [coder decodeBoolForKey:ACCPublishAudioAuditTaskSELToStr(useTmpPath)];
    return task;
}

- (id)copyWithZone:(NSZone *)zone {
    ACCPublishAudioAuditTask *tmp = [ACCPublishAudioAuditTask new];
    tmp.awemeId = self.awemeId;
    tmp.createTimeInterval = self.createTimeInterval;
    tmp.audioFilePath = self.audioFilePath;
    tmp.useTmpPath = self.useTmpPath;
    return tmp;
}

@end

static NSString * const kACCPublishAudioAuditManagerSuitName = @"com.bytedance.shortVideo.tool.audioAudit";
static NSString * const kACCPublishAudioAuditManagerStoreKey = @"ACCPublishAudioAuditManagerStoreKey";

typedef void(^ACCPublishAudioAuditManagerReqUploadParamCompletion)(NSError *error);

@interface ACCPublishAudioAuditManager ()
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSMutableArray<ACCPublishAudioAuditTask *> *tasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<ACCFileUploadServiceProtocol>> *uploadServiceDict;
@property (nonatomic, strong) AWEResourceUploadParametersResponseModel *uploadParameters;
@end

@implementation ACCPublishAudioAuditManager

+ (instancetype)sharedInstance {
    static ACCPublishAudioAuditManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [ACCPublishAudioAuditManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uploadServiceDict = @{}.mutableCopy;
        [self loadData];
    }
    return self;
}

- (void)loadData {
    NSData *data = [self.userDefaults objectForKey:kACCPublishAudioAuditManagerStoreKey];
    if (!data) {
        self.tasks = @[].mutableCopy;
    } else {
        NSArray<ACCPublishAudioAuditTask *> *tasks = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        if (tasks) {
            self.tasks = tasks.mutableCopy;
        } else {
            self.tasks = @[].mutableCopy;
        }
    }
}

- (void)saveData {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.tasks];
    [self.userDefaults setObject:data forKey:kACCPublishAudioAuditManagerStoreKey];
}

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
       _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:kACCPublishAudioAuditManagerSuitName];
    }
    return _userDefaults;
}

/// generate folder: /Document/studioAudioAudit/
- (NSString *)audioAuditFolderPath {
    NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *audioAuditFolder = [documentsDir stringByAppendingPathComponent:@"studioAudioAudit"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:audioAuditFolder]) {
        NSError *error = nil;
        BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:audioAuditFolder withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            return nil;
        }
    }
    return audioAuditFolder;
}

- (void)addAudioAuditTask:(ACCPublishAudioAuditTask *)task {
    if (!task || !task.awemeId || !task.audioFilePath) {
        return;
    }
    BOOL audioFileExist = [NSFileManager.defaultManager fileExistsAtPath:task.audioFilePath];
    if (!audioFileExist) {
        return;
    }
    
    long long fileSize = -1;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:task.audioFilePath error:NULL];
    if (fileAttributes) {
        fileSize = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
    }
    if (fileSize <= 0) {
        NSError *error = [NSError errorWithDomain:@"AudioOrignalPathDomain" code:1 userInfo:nil];
        [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageFileCheck task:task materialId:nil error:error response:nil];
        return;
    }
    
    NSString *newAudioFilePath = [[self audioAuditFolderPath] stringByAppendingPathComponent:task.audioFilePath.lastPathComponent];
    NSError *error = nil;
    // try to copy audio file to documents from tmp to prevent to be deleted by system.
    [NSFileManager.defaultManager copyItemAtPath:task.audioFilePath toPath:newAudioFilePath error:&error];
    if (!error) {
        task.useTmpPath = NO;
        task.audioFilePath = newAudioFilePath.lastPathComponent;
    }
    
    __block BOOL shouldAdd = YES;
    [self.tasks enumerateObjectsUsingBlock:^(ACCPublishAudioAuditTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.awemeId isEqualToString:task.awemeId]) {
            shouldAdd = NO;
            *stop = YES;
        }
    }];
    if (!shouldAdd) {
        return;
    }
    
    [self.tasks addObject:task];
    [self saveData];
}

- (void)removeAudioAuditTask:(ACCPublishAudioAuditTask *)task {
    if (!task || !task.awemeId || !task.audioFilePath) {
        return;
    }
    if ([self.tasks containsObject:task]) {
        [self.tasks removeObject:task];
    } else {
        __block ACCPublishAudioAuditTask *task = nil;
        [self.tasks enumerateObjectsUsingBlock:^(ACCPublishAudioAuditTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.awemeId isEqualToString:task.awemeId]) {
                task = obj;
                *stop = YES;
            }
        }];
        if (task) {
            [self.tasks removeObject:task];
        }
    }
    [self saveData];
}

- (void)retryAuidtProcessIfNeeded {
    if (self.tasks.count < 1) {
        return;
    }
    const NSArray *tasks = [self.tasks copy];
    @weakify(self);
    [self p_requestUploadParamsWithCompletion:^(NSError *error) {
        @strongify(self);
        if (!error) {
            [tasks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self p_uploadTask:obj];
            }];
        } else {
            [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageRequestUploadParams task:nil materialId:nil error:error response:nil];
        }
    }];
}

- (void)p_uploadTask:(ACCPublishAudioAuditTask *)task
{
    if (!task || !task.awemeId || !task.audioFilePath) {
        return;
    }
    NSString *fullPath = task.useTmpPath ? task.audioFilePath : [[self audioAuditFolderPath] stringByAppendingPathComponent:task.audioFilePath.lastPathComponent];
    
    long long fileSize = -1;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    if (fileAttributes) {
        fileSize = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
    }
    
    BOOL audioFileExist = [NSFileManager.defaultManager fileExistsAtPath:fullPath];
    if (!audioFileExist || fileSize <= 0) {
        NSError *error = [NSError errorWithDomain:@"AudioOrignalPathDomain" code:2 userInfo:nil];
        [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageFileCheck task:nil materialId:nil error:error response:nil];
        [self removeAudioAuditTask:task];
        return;
    }
    
    ACCFileUploadServiceBuilder *uploadBuilder = [[ACCFileUploadServiceBuilder alloc] init];
    id<ACCFileUploadServiceProtocol> uploadService = [uploadBuilder createUploadServiceWithParams:self.uploadParameters filePath:fullPath fileType:ACCUploadFileTypeAudio];
    
    [self.uploadServiceDict setObject:uploadService forKey:task.awemeId];
    
    NSProgress *progress = nil;
    @weakify(self);
    [uploadService uploadFileWithProgress:&progress completion:^(ACCFileUploadResponseInfoModel *uploadInfoModel, NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"audio", AWELogToolTagPublish, @"upload audio error. error: %@, filePath: %@, exist: %d", error, fullPath, [NSFileManager.defaultManager fileExistsAtPath:fullPath]);
        }
        
        if (uploadInfoModel.materialId) {
            NSMutableDictionary *parameter = @{}.mutableCopy;
            parameter[@"aweme_id"] = task.awemeId;
            parameter[@"audiotrack_uri"] = uploadInfoModel.materialId;
            let audioNetService = IESAutoInline(ACCBaseServiceProvider(), ACCAudioNetServiceProtocol);
            [audioNetService updateAudioTrackWithId:task.awemeId audiotrackUri:uploadInfoModel.materialId completion:^(id  _Nullable model, NSError * _Nullable error) {
                @strongify(self);
                if ([model isKindOfClass:[NSDictionary class]]) {
                  if (model[@"status_code"] && [model[@"status_code"] integerValue] == 0) {
                      [self.uploadServiceDict removeObjectForKey:task.awemeId];
                      [self removeAudioAuditTask:task];
                      [NSFileManager.defaultManager removeItemAtPath:fullPath error:nil];
                      [self monitorUploadAudioRate:YES stage:AWEAudioAuditStageTrack task:task materialId:uploadInfoModel.materialId error:error response:model];
                  } else {
                      [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageTrack task:task materialId:uploadInfoModel.materialId error:error response:model];
                  }
                } else {
                    [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageTrack task:task materialId:uploadInfoModel.materialId error:error response:nil];
                }
            }];
        } else {
            [self monitorUploadAudioRate:NO stage:AWEAudioAuditStageUpload task:task materialId:nil error:error response:nil];
        }
    }];
}

- (void)p_requestUploadParamsWithCompletion:(ACCPublishAudioAuditManagerReqUploadParamCompletion)completion {
    if (self.uploadParameters.videoUploadParameters) {
        ACCBLOCK_INVOKE(completion, nil);
    } else {
        @weakify(self);
        [IESAutoInline(ACCBaseServiceProvider(), ACCPublishNetServiceProtocol) requestUploadParametersWithCompletion:^(AWEResourceUploadParametersResponseModel *parameters, NSError *error) {
            @strongify(self);
            if (parameters.videoUploadParameters && !error) {
                self.uploadParameters = parameters;
                ACCBLOCK_INVOKE(completion, nil);
            } else {
                ACCBLOCK_INVOKE(completion, error);
            }
        }];
    }
}

- (void)monitorUploadAudioRate:(BOOL)success stage:(AWEAudioAuditStage)stage task:(ACCPublishAudioAuditTask *)task materialId:(NSString *)materialId error:(NSError *)error response:(NSDictionary *)response {
    NSMutableDictionary *logData = @{
        @"materialId" : materialId ? : @"",
        @"aweme_id"   : task.awemeId ? : @"",
        @"backup_upload" : @(1),
        @"stage" : @(stage)
    }.mutableCopy;
    
    if (!success) {
        [logData addEntriesFromDictionary:@{
            @"errorCode"    : @(error.code).description,
            @"errorDesc"    : error.localizedDescription ? : @"null",
            @"errorDomain"  : error.domain ? : @"null",
            @"response"     : response.description ? : @"null",
            @"url"          : task.audioFilePath ? (task.useTmpPath ? task.audioFilePath : [[self audioAuditFolderPath] stringByAppendingPathComponent:task.audioFilePath.lastPathComponent] ) : @"null",
        }];
    }

    [ACCMonitor() trackService:@"aweme_publish_upload_audio_rate" status:success ? 0 : 1 extra:logData.copy];
}


@end
