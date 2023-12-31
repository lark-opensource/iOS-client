//
//  TSPKAPICostTimeManager.m
//  TT2
//
//  Created by bytedance on 2022/4/20.
//

#import "TSPKAPICostTimeManager.h"
#import "TSPKLock.h"
#import "TSPKLogger.h"
#import "TSPKEvent.h"
#import "TSPKConfigs.h"
#import "TSPKStatisticEvent.h"
#import "TSPKReporter.h"

@interface TSPKAPITimeModel : NSObject

@property (nonatomic, assign) CFAbsoluteTime customAPICallTime;
@property (nonatomic, assign) CFAbsoluteTime systemAPIBeginTime;
@property (nonatomic, assign) CFAbsoluteTime systemAPIEndTime;

@end

@implementation TSPKAPITimeModel

- (void)clear {
    self.customAPICallTime = 0;
    self.systemAPIBeginTime = 0;
    self.systemAPIEndTime = 0;
}

- (CFAbsoluteTime)systemAPICostTime {
    if (self.systemAPIBeginTime < DBL_EPSILON ||
        self.systemAPIEndTime < DBL_EPSILON ||
        (self.systemAPIEndTime - self.systemAPIBeginTime) < DBL_EPSILON) {
        return 0;
    } else {
        return self.systemAPIEndTime - self.systemAPIBeginTime;
    }
}

- (CFAbsoluteTime)customAPICostTime {
    if (self.systemAPIBeginTime < DBL_EPSILON ||
        self.customAPICallTime < DBL_EPSILON ||
        (self.systemAPIBeginTime - self.customAPICallTime) < DBL_EPSILON) {
        return 0;
    } else {
        return self.systemAPIBeginTime - self.customAPICallTime;
    }
}

@end


@interface TSPKSingleAPICostTimeUploader : NSObject

@property (nonatomic, copy) NSString *apiType;
@property (nonatomic, strong) NSMutableArray <NSNumber *> *customCallTimeArray;
@property (nonatomic, strong) NSMutableDictionary <NSString *, TSPKAPITimeModel *> *systemCallInfo;
@property (nonatomic, strong) id<TSPKLock> lock;
@property (nonatomic, copy) NSString *customUploadTitle;
@property (nonatomic, copy) NSString *uploadTitle;

@end

@implementation TSPKSingleAPICostTimeUploader

- (instancetype)initWithApiType:(NSString *)apiType
                    uploadTitle:(NSString *)uploadTitle
              customUploadTitle:(NSString *)customUploadTitle {
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _apiType = apiType;
        _uploadTitle = uploadTitle.copy;
        _customUploadTitle = customUploadTitle.copy;
        _customCallTimeArray = [NSMutableArray array];
        _systemCallInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)handleAPIAccessWithHashTag:(NSString *)hashTag beforeOrAfter:(BOOL)beforeOrAfter {
    
    if (hashTag.length == 0) {
        return;
    }
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    [self.lock lock];
    TSPKAPITimeModel *timeModel = self.systemCallInfo[hashTag];
    
    if (beforeOrAfter) {
        if (!timeModel) {
            timeModel = [TSPKAPITimeModel new];
            self.systemCallInfo[hashTag] = timeModel;
        }
        
        timeModel.systemAPIBeginTime = currentTime;
        
        if (self.customCallTimeArray.count > 0) {
            timeModel.customAPICallTime = [self.customCallTimeArray[0] doubleValue];
            [self.customCallTimeArray removeObjectAtIndex:0];
            
            CFAbsoluteTime costTime = [timeModel customAPICostTime];
            if (costTime >= DBL_EPSILON) {
                NSString *key = [self getCustomStatisticsKey];
                NSNumber *value = @(costTime * 1000);
                [self reportWithInfo:@{key : value}];
            }
        }
    } else {
        if (timeModel) {
            timeModel.systemAPIEndTime = currentTime;
            CFAbsoluteTime costTime = [timeModel systemAPICostTime];
            if (costTime >= DBL_EPSILON) {
                NSString *key = [self getDefaultStatisticsKey];
                NSNumber *value = @(costTime * 1000);
                [self reportWithInfo:@{key : value}];
            }
            
            [timeModel clear];
        }
    }
    
    [self.lock unlock];
}

- (NSString *)getCustomStatisticsKey {
    return [self getKeyWithContent:self.customUploadTitle];
}

- (NSString *)getDefaultStatisticsKey {
    return [self getKeyWithContent:self.uploadTitle];
}

- (NSString *)getKeyWithContent:(NSString *)content {
    return [NSString stringWithFormat:@"%@_%@_cost_time", [self.apiType lowercaseString], content];
}

- (void)handleCustomAPIAccess {
    [self.lock lock];
    [self.customCallTimeArray addObject:@(CFAbsoluteTimeGetCurrent())];
    [self.lock unlock];
}

- (void)reportWithInfo:(NSDictionary *)info {
    NSString *serviceName = @"tspk_api_cost_time_statistics";
    TSPKStatisticEvent *event = [TSPKStatisticEvent initWithService:serviceName metric:info category:nil attributes:nil];
    
    [[TSPKReporter sharedReporter] report:event];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:info];
}

@end

@interface TSPKAPICostTimeManager()

@property (nonatomic, strong) NSMutableDictionary <NSString *, TSPKSingleAPICostTimeUploader*> *uploaderDic;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKAPICostTimeManager

+ (instancetype)sharedInstance {
    static TSPKAPICostTimeManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TSPKAPICostTimeManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _uploaderDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)uniqueId {
    return @"TSPKAPICostTimeManager";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return [[TSPKConfigs sharedConfig] isEnableUploadAPICostTimeStatistics];
}

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *)event {
    TSPKAPIModel *apiModel = event.eventData.apiModel;
    NSString *apiType = apiModel.pipelineType;
    TSPKAPIUsageType apiUsageType = apiModel.apiUsageType;
    BOOL isCustomApi = apiModel.isCustomApi;
        
    NSString *key;
    NSString *uploadTitle;
    NSString *customUploadTitle;
    
    if (apiType == TSPKPipelineVideoOfAVCaptureSession || apiType == TSPKPipelineAudioOfAudioOutput) {
        if (apiUsageType == TSPKAPIUsageTypeStop || apiUsageType == TSPKAPIUsageTypeStart) {
            uploadTitle = apiUsageType == TSPKAPIUsageTypeStart ? @"start" : @"stop";
            key = [NSString stringWithFormat:@"%@_%@", apiType, uploadTitle];
        }
    } else {
        key = [NSString stringWithFormat:@"%@_%@", apiModel.pipelineType, apiModel.apiMethod];
        uploadTitle = apiModel.apiMethod;
    }
    
    customUploadTitle = [NSString stringWithFormat:@"custom_to_system_%@", uploadTitle];
    
    [self.lock lock];
    TSPKSingleAPICostTimeUploader *uploader = self.uploaderDic[key];
    if (!uploader) {
        uploader = [[TSPKSingleAPICostTimeUploader alloc] initWithApiType:apiType uploadTitle:uploadTitle customUploadTitle:customUploadTitle];
        self.uploaderDic[key] = uploader;
    }
    [self.lock unlock];
    
    if (isCustomApi) {
        [uploader handleCustomAPIAccess];
    } else {
        [uploader handleAPIAccessWithHashTag:apiModel.hashTag beforeOrAfter:apiModel.beforeOrAfterCall];
    }
    
    return nil;
}

@end

