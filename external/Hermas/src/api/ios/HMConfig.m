//
//  HMConfig.m
//  Hermas
//
//  Created by 崔晓兵 on 20/1/2022.
//

#import "HMConfig.h"

NSString * const kModuleUploadSuccess = @"kModuleUploadSuccess";

@implementation HMRequestModel
- (void)setRequestURL:(NSString *)requestURL {
    _requestURL = [requestURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
}
@end

@implementation HMModuleConfig
@synthesize name;
@synthesize domain;
@synthesize path;
@synthesize maxStoreSize;
@synthesize zstdDictType;
@synthesize forwardEnabled;
@synthesize forwardUrl;
@synthesize cloudCommandBlock;
@synthesize enableEncrypt;
@synthesize isForbidSplitReportFile;
@synthesize enableRawUpload;
@synthesize aggregateParam;
@synthesize downgradeBlock;
@synthesize downgradeRuleUpdateBlock;
@synthesize tagVerifyBlock;
@synthesize shareRecordThread;
@synthesize maxLocalStoreSize;

@end

@implementation HMGlobalConfig
@synthesize maxStoreSize;
@synthesize maxStoreTime;
@synthesize maxFileSize;
@synthesize maxLogNumber;
@synthesize maxReportSize;
@synthesize reportInterval;
@synthesize limitReportSize;
@synthesize limitReportInterval;
@end


@implementation HMAggregateParam

@end

@implementation HMInstanceConfig

- (instancetype)initWithModuleId:(NSString *)moduleId aid:(NSString *)aid {
    if (self = [super init]) {
        _moduleId = moduleId;
        _aid = aid;
        _enableAggregate = NO;
        _enableSemiFinished = NO;
    }
    return self;
}

@end


@implementation HMSearchCondition

@end


@interface HMSearchAndCondition()
@property (nonatomic, strong) NSMutableArray<HMSearchCondition *> *internalConditions;
@end

@implementation HMSearchAndCondition
- (instancetype)init {
    if (self = [super init]) {
        _internalConditions = @[].mutableCopy;
    }
    return self;
}

- (void)addCondition:(HMSearchCondition *)condition {
    [_internalConditions addObject:condition];
}

- (NSArray<HMSearchCondition *> *)conditions {
    return [_internalConditions copy];
}
@end


@interface HMSearchOrCondition()
@property (nonatomic, strong) NSMutableArray<HMSearchCondition *> *internalConditions;
@end

@implementation HMSearchOrCondition
- (instancetype)init {
    if (self = [super init]) {
        _internalConditions = @[].mutableCopy;
    }
    return self;
}

- (void)addCondition:(HMSearchCondition *)condition {
    [_internalConditions addObject:condition];
}

- (NSArray<HMSearchCondition *> *)conditions {
    return [_internalConditions copy];
}
@end


@implementation HMSearchParam

@end
