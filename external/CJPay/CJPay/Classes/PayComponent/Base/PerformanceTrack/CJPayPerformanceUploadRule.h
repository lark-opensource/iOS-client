//
//  CJPayPerformanceUploadRule.h
//  Pods
//
//  Created by 王新华 on 2021/10/14.
//

#import <JSONModel/JSONModel.h>
#import "CJPayPerformanceStage.h"

NS_ASSUME_NONNULL_BEGIN

//{
//    "type": "head_to_end", // 从前往后找  head_to_end | end_to_head
//    "head": {
//        "type": "api_start",
//        "page_name": "",
//        "name": "",
//        "need_extra": true // 为true的话，会把extra数据拼接到新的埋点内部。
//    }, // 开始点特征
//    "end": {
//        "type": "api_start",
//        "page_name": "",
//        "name": "",
//        "need_extra": true,
//    },  // 结束点特征
//    "new_event_name": "" // 映射成的新EventName,
//    "load_time": "",
//}

// 文档地址：https://bytedance.feishu.cn/docs/doccnhekLW741eqFGaNyyS3JXgt#

@interface CJPayPerformanceUploadNode : JSONModel<NSCopying>

@property (nonatomic, copy) NSString *typeStr;
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL need_extra;

- (CJPayPerformanceStageType)curType;

@end

@interface CJPayPerformanceUploadNode(Match)

- (BOOL)matchToPerformanceStage:(CJPayPerformanceStage *)stage;

@end

@interface CJPayPerformanceUploadRule : JSONModel<NSCopying>

@property (nonatomic, copy) NSString *searchMethod;
@property (nonatomic, strong) CJPayPerformanceUploadNode *headNode;
@property (nonatomic, strong) CJPayPerformanceUploadNode *endNode;
@property (nonatomic, copy) NSString *mapToEventName;

- (BOOL)isValid;
- (BOOL)isHeadToEnd;
- (BOOL)isEndToHead;

@end

@interface CJPayPerformanceUploadRule(Process)

@property (nonatomic, strong, readonly) NSMutableArray<NSDictionary *> *events;
@property (nonatomic, strong, nullable) CJPayPerformanceStage *headStage;
@property (nonatomic, strong, nullable) CJPayPerformanceStage *endStage;

- (void)processStage:(CJPayPerformanceStage *)stage;
- (void)uploadEvents:(void (^)(NSArray<NSDictionary *> *events))uploadBlock;

@end

@protocol CJPayPerformanceUploadRule;
@interface CJPayPerformanceMonitorModel : JSONModel

@property (nonatomic, copy) NSArray<CJPayPerformanceUploadRule> *uploadRules;

@end

NS_ASSUME_NONNULL_END
