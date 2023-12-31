//
//  HMInstance.m
//  Hermas
//
//  Created by 崔晓兵 on 19/1/2022.
//

#import "HMInstance.h"
#import "HMConfig.h"
#import "HMTools.h"
#import "log.h"
#include "hermas.hpp"
#include "search_service.h"
#include "condition_node.h"
#include "json_util.h"

#import <libkern/OSAtomic.h>
#import <map>
#import <mutex>

#define SAFE_UTF8_STRING(x) (x ?  x.UTF8String : "")

using namespace hermas;

static NSString * const kEnableUpload = @"enable_upload";

@interface HMInstance ()
@end


@implementation HMInstance {
    std::map<HMRecordPriority, std::shared_ptr<hermas::Recorder>> _container;
    std::mutex _mutex;
    std::unique_ptr<hermas::Hermas> _hermas;
}

- (instancetype)initWithConfig:(HMInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
        [self buildHermasInstance];
    }
    return self;
}

- (BOOL)isDropData {
    return _hermas->IsDropData();
}

- (BOOL)isServerAvailable {
    return _hermas->IsServerAvailable();
}

- (void)cleanAllCache {
    return _hermas->CleanAllCache();
}

- (void)UploadWithFlushImmediately {
    return _hermas->UploadWithFlushImmediately();
}

- (void)setSequenceNumberGenerator:(int64_t (^)())sequenceNumberGenerator {
    _sequenceNumberGenerator = [sequenceNumberGenerator copy];
    auto env = Env::GetInstance(SAFE_UTF8_STRING(_config.moduleId), SAFE_UTF8_STRING(_config.aid));
    if (!env) {
        loge("instance", "there is something wrong with env, moduleid = %s, aid = %s", SAFE_UTF8_STRING(_config.moduleId), SAFE_UTF8_STRING(_config.aid));
        return;
    }
    __weak __typeof(self) wself = self;
    env->sequence_number_generator = [wself]() -> int64_t {
        return wself.sequenceNumberGenerator();
    };
}

- (void)recordData:(NSDictionary *)dic {
    [self recordData:dic priority:HMRecordPriorityDefault];
}

- (void)recordData:(NSDictionary *)dic priority:(HMRecordPriority)priority {
    [self recordData:dic priority:priority forceSave:NO];
}

- (void)recordData:(nonnull NSDictionary *)dic priority:(HMRecordPriority)priority forceSave:(BOOL)forceSave {
    std::shared_ptr<hermas::Recorder> recorder = [self recorderWithPriority:priority];

    // the default value of enableUpload is YES if there is no enable_upload key
    id enableUploadNumber = [dic valueForKey:kEnableUpload];
    bool enableUpload = enableUploadNumber ? [enableUploadNumber boolValue] : YES;
    
    // remove enable_upload key
    NSMutableDictionary *mutableDic = [dic mutableCopy];
    [mutableDic removeObjectForKey:kEnableUpload];
    
    // modify value of log_type(only for performance_monitor) key if it will record to local
    BOOL needUpload = enableUpload || priority == HMRecordPriorityRealTime;
    if (!needUpload && [[mutableDic valueForKey:@"log_type"] isEqualToString:@"performance_monitor"] ) {
        [mutableDic setValue:@"performance_monitor_debug" forKey:@"log_type"];
    }
    
    // convert dic to string
    NSString *str = stringWithDictionary(mutableDic);
    if (str.length <= 0) {
        loge("instance", "invalid data %s", SAFE_UTF8_STRING(str));
        return;
    }
    
    // record
    if (needUpload) {
        recorder->DoRecord(SAFE_UTF8_STRING(str));
    } else {
        recorder->DoRecordLocal(SAFE_UTF8_STRING(str), forceSave);
    }
}

- (void)recordLocal:(NSDictionary *)dic forceSave:(BOOL)forceSave {
    std::shared_ptr<hermas::Recorder> recorder = [self recorderWithPriority:HMRecordPriorityDefault];
    
    NSString *str = stringWithDictionary(dic);
    if (str.length <= 0) {
        loge("instance", "invalid data %s", SAFE_UTF8_STRING(str));
        return;
    }
    recorder->DoRecordLocal(SAFE_UTF8_STRING(str), forceSave);
}

- (void)recordCache:(NSDictionary *)dic {
    std::shared_ptr<hermas::Recorder> recorder = [self recorderWithPriority:HMRecordPriorityDefault];
    
    NSString *str = stringWithDictionary(dic);
    if (str.length <= 0) {
        loge("instance", "invalid data %s", SAFE_UTF8_STRING(str));
        return;
    }
    recorder->DoRecordCache(SAFE_UTF8_STRING(str));
}

- (void)stopCache {
    logi("instance", "stop cache, moduleid = %s, aid = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid));
    _hermas->StopCache();
}

- (void)aggregateData:(NSDictionary *)dic {
    id enableUploadNumber = [dic valueForKey:kEnableUpload];
    bool enableUpload = enableUploadNumber ? [enableUploadNumber boolValue] : YES;
    
    NSString *str = stringWithDictionary(dic);
    if (enableUpload) {
        _hermas->Aggregate(SAFE_UTF8_STRING(str));
    } else {
        std::shared_ptr<hermas::Recorder> recorder = [self recorderWithPriority:HMRecordPriorityDefault];
        recorder->DoRecordLocal(SAFE_UTF8_STRING(str), NO);
    }
    
}

- (void)stopAggregate:(bool)isLaunchReport {
    logd("instance", "stop aggregate, moduleid = %s, aid = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid));
    _hermas->StopAggregate(isLaunchReport);
}

- (void)startSemiTraceRecord:(NSDictionary *)record {
    NSString *traceID = [record valueForKey:@"trace_id"];
    NSString *serviceName = [record valueForKey:@"service"];
    logd("instance", "Start Semi_Trace. moduleid = %s, aid = %s, Trace = %s, TraceID = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid), SAFE_UTF8_STRING(serviceName), SAFE_UTF8_STRING(traceID));
    if (!traceID) {
        return;
    }
    _hermas->StartSemiTraceRecord((stringWithDictionary(record)).UTF8String, SAFE_UTF8_STRING(traceID));
}

- (void)startSemiSpanRecord:(NSDictionary *)record {
    NSString *traceID = [record valueForKey:@"trace_id"];
    NSString *SpanID = [record valueForKey:@"span_id"];
    NSString *operationName = [record valueForKey:@"operation_name"];
    logd("instance", "FinishSpan, moduleid = %s, aid = %s, Span = %s, SpanID = %s, TraceID = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid), SAFE_UTF8_STRING(operationName), SAFE_UTF8_STRING(SpanID), SAFE_UTF8_STRING(traceID));
    if (!traceID || !SpanID) {
        return;
    }
    _hermas->StartSemiSpanRecord((stringWithDictionary(record)).UTF8String, SAFE_UTF8_STRING(traceID), SAFE_UTF8_STRING(SpanID));
}

- (void)finishSemiTraceRecord:(NSDictionary *)record WithSpanIdList:(NSArray *)spanIDList{
    NSString *traceID = [record valueForKey:@"trace_id"];
    NSString *serviceName = [record valueForKey:@"service"];
    logd("instance", "Finish Semi_Trace. moduleid = %s, aid = %s, Trace = %s, TraceID = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid), SAFE_UTF8_STRING(serviceName), SAFE_UTF8_STRING(traceID));
    _hermas->FinishSemiTraceRecord((stringWithDictionary(record)).UTF8String, SAFE_UTF8_STRING(traceID), stringWithNSArray(spanIDList));
}

- (void)finishSemiSpanRecord:(NSDictionary *)record {
    NSString *traceID = [record valueForKey:@"trace_id"];
    NSString *SpanID = [record valueForKey:@"span_id"];
    NSString *operationName = [record valueForKey:@"operation_name"];
    logd("instance", "FinishSpan, moduleid = %s, aid = %s, Span = %s, SpanID = %s, TraceID = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid), SAFE_UTF8_STRING(operationName), SAFE_UTF8_STRING(SpanID), SAFE_UTF8_STRING(traceID));
    _hermas->FinishSemiSpanRecord(((stringWithDictionary(record)).UTF8String), SAFE_UTF8_STRING(traceID), SAFE_UTF8_STRING(SpanID));
}

- (void)deleteSemifinishedRecords:(NSString *)traceID WithSpanIdList:(NSArray *)spanIDList {
    logd("instance", "delete semifinished records, moduleid = %s, aid = %s, traceId = %s", SAFE_UTF8_STRING(self.config.moduleId), SAFE_UTF8_STRING(self.config.aid), SAFE_UTF8_STRING(traceID));
    _hermas->DeleteSemifinishedRecords(SAFE_UTF8_STRING(traceID), stringWithNSArray(spanIDList));
}

- (void)launchReportForSemi {
    _hermas->LaunchReportForSemi();
}

- (void)updateReportHeader:(NSDictionary *)reportHeader {
    std::string header = stringWithDictionary(reportHeader).UTF8String;
    _hermas->UpdateReportHeader(header);
}

- (NSDictionary<NSString*, NSArray*> *)searchWithCondition:(HMSearchCondition *)condition {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    std::shared_ptr<hermas::ConditionNode> internalNode = [self nodeWithCondition:condition];
    std::vector<std::unique_ptr<SearchData>> ret = _hermas->Search(internalNode);
    for (auto& data : ret) {
        NSMutableArray *arr = [NSMutableArray array];
        for(auto& record : data->records) {
            [arr addObject:[NSString stringWithUTF8String:record.c_str()]];
        }
        NSString *key = [NSString stringWithFormat:@"%s", data->filename.c_str()];
        [result setValue:arr forKey:key];
    }
    return result;
}

- (void)UploadLocalData {
    _hermas->UploadLocalData();
}

#pragma mark - Private

- (std::shared_ptr<hermas::Recorder>)recorderWithPriority:(HMRecordPriority)priority {
    std::shared_ptr<hermas::Recorder> recorder = nullptr;
    std::lock_guard<std::mutex> lock(_mutex);
    if (_container.find(priority) != _container.end()) {
        recorder = _container[priority];
    } else {
        recorder = _hermas->CreateRecorder((hermas::RECORD_INTERVAL)priority);
        _container[priority] = recorder;
    }
    return recorder;
}

- (void)buildHermasInstance {
    _hermas = std::make_unique<Hermas>(SAFE_UTF8_STRING(_config.moduleId), SAFE_UTF8_STRING(_config.aid));
    std::shared_ptr<hermas::Env> env = std::make_shared<hermas::Env>();
    env->SetModuleId(SAFE_UTF8_STRING(_config.moduleId));
    env->SetAid(SAFE_UTF8_STRING(_config.aid));
    env->SetPid(std::to_string(getpid()).c_str());
    env->SetEnableAggregator(_config.enableAggregate);
    env->SetEnableSemiFinished(_config.enableSemiFinished);
    env->SetReportLowLevelHeader(GlobalEnv::GetInstance().GetReportLowLevelHeader());
    _hermas->InitInstanceEnv(env);
}

- (std::shared_ptr<hermas::ConditionNode>)nodeWithCondition:(HMSearchCondition *)condition {
    if ([condition isMemberOfClass:[HMSearchAndCondition class]]) {
        HMSearchAndCondition *andCondition = (HMSearchAndCondition *)condition;
        auto root = std::make_shared<hermas::ConditionAndNode>();
        [andCondition.conditions enumerateObjectsUsingBlock:^(HMSearchCondition * _Nonnull condition, NSUInteger idx, BOOL * _Nonnull stop) {
            std::shared_ptr<hermas::ConditionNode> node = [self nodeWithCondition:condition];
            root->AddChildNode(node);
        }];
        return root;
    } else if ([condition isMemberOfClass:[HMSearchOrCondition class]]) {
        HMSearchOrCondition *orCondition = (HMSearchOrCondition *)condition;
        auto root = std::make_shared<hermas::ConditionOrNode>();
        [orCondition.conditions enumerateObjectsUsingBlock:^(HMSearchCondition * _Nonnull condition, NSUInteger idx, BOOL * _Nonnull stop) {
            std::shared_ptr<hermas::ConditionNode> node = [self nodeWithCondition:condition];
            root->AddChildNode(node);
        }];
        return root;
    } else {
        auto leafNode = std::make_shared<hermas::ConditionLeafNode>(hermas::ConditionJudgeType(condition.judgeType),
                                                                   std::string(SAFE_UTF8_STRING(condition.key)),
                                                                   condition.threshold,
                                                                    condition.stringValue ? std::string(condition.stringValue.UTF8String) : "");
        return leafNode;
    }
}

@end
