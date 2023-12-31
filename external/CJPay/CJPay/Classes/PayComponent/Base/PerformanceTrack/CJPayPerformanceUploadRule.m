//
//  CJPayPerformanceUploadRule.m
//  Pods
//
//  Created by 王新华 on 2021/10/14.
//

#import "CJPayPerformanceUploadRule.h"
#import "CJPaySDKMacro.h"
#import <objc/runtime.h>

@implementation CJPayPerformanceUploadNode

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"typeStr" : @"type",
        @"pageName" : @"pageName",
        @"name" : @"name",
        @"need_extra" : @"need_extra",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayPerformanceUploadNode *)copyWithZone:(NSZone *)zone {
    CJPayPerformanceUploadNode *copyNode = [CJPayPerformanceUploadNode new];
    copyNode.typeStr = self.typeStr;
    copyNode.pageName = self.pageName;
    copyNode.name = self.name;
    copyNode.need_extra = self.need_extra;
    return copyNode;
}

- (CJPayPerformanceStageType)curType {
    NSDictionary *strToType = @{
        @"api_start" : @(CJPayPerformanceStageTypeAPIStart),
        @"api_end" : @(CJPayPerformanceStageTypeAPIEnd),
        @"request_start" : @(CJPayPerformanceStageTypeRequestStart),
        @"request_end" : @(CJPayPerformanceStageTypeRequestEnd),
        @"page_init" : @(CJPayPerformanceStageTypePageInit),
        @"page_appear" : @(CJPayPerformanceStageTypePageAppear),
        @"page_finish_render" : @(CJPayPerformanceStageTypePageFinishRender),
        @"page_disappear" : @(CJPayPerformanceStageTypePageDisappear),
        @"page_dealloc" : @(CJPayPerformanceStageTypePageDealloc),
        @"action_btn" : @(CJPayPerformanceStageTypeActionBtn),
        @"action_cell" : @(CJPayPerformanceStageTypeActionCell),
        @"action_gesture" : @(CJPayPerformanceStageTypeActionGesture),
    };
    return (CJPayPerformanceStageType)[strToType cj_intValueForKey:self.typeStr];
}

@end

@implementation CJPayPerformanceUploadNode(Match)

// 特定type时，其他参数可以为空。
// 其他type 和 name均不能为空，PageName可选如果传入，则参数匹配
- (BOOL)isValid {
    NSSet *onlyNeedTypeStrSet = [NSSet setWithArray:@[@"api_start", @"api_end", @"page_init", @"page_finish_render"]];
    if ([onlyNeedTypeStrSet containsObject:self.typeStr]) {
        return YES;
    }
    return Check_ValidString(self.name) && Check_ValidString(self.typeStr);
}

- (BOOL)matchToPerformanceStage:(CJPayPerformanceStage *)stage {
    
    if (![stage isValid] || ![self isValid]) {
        return NO;
    }
    CJPayPerformanceStageType nodeType = [self curType];
    CJPayLogAssert(nodeType != CJPayPerformanceStageTypeNone, @"配置的type不正确，导致不能采集信息");
    
    if (stage.stageType == nodeType) {
        if (Check_ValidString(self.name)) {
            BOOL matched = [stage.name isEqualToString:self.name];
            if (matched && Check_ValidString(self.pageName)) {
                return [stage.pageName isEqualToString:self.pageName];
            }
            return matched;
        }
        NSSet *onlyNeedTypeSet = [NSSet setWithArray:@[@(CJPayPerformanceStageTypeAPIStart),@(CJPayPerformanceStageTypeAPIEnd),@(CJPayPerformanceStageTypePageInit),@(CJPayPerformanceStageTypePageFinishRender)]];
        return [onlyNeedTypeSet containsObject:@(nodeType)];
    }
    
    return NO;
}

@end



@implementation CJPayPerformanceUploadRule

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"searchMethod" : @"search_method",
        @"headNode" : @"head_node",
        @"endNode" : @"end_node",
        @"mapToEventName" : @"new_event_name",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (CJPayPerformanceUploadRule *)copyWithZone:(NSZone *)zone {
    CJPayPerformanceUploadRule *copyRule = [CJPayPerformanceUploadRule new];
    copyRule.searchMethod = self.searchMethod;
    copyRule.headNode = [self.headNode copy];
    copyRule.endNode = [self.endNode copy];
    copyRule.mapToEventName = self.mapToEventName;
    
    return copyRule;
}

- (BOOL)isValid {
    return [self.headNode isValid] && [self.endNode isValid];
}

- (BOOL)isEndToHead {
    return [self.searchMethod isEqualToString:@"end_to_head"];
}

- (BOOL)isHeadToEnd {
    return !Check_ValidString(self.searchMethod) || [self.searchMethod isEqualToString:@"head_to_end"];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{ event_name = %@, head_node = [name = %@, type = %@], end_node = [name = %@, type = %@], search_method = %@ }", self.mapToEventName, self.headNode.name, self.headNode.typeStr, self.endNode.name, self.endNode.typeStr, self.searchMethod];
}

@end

@implementation CJPayPerformanceUploadRule(Process)

- (void)processStage:(CJPayPerformanceStage *)stage {
    if ([self isHeadToEnd]) {
        [self p_processHeadToEndStage:stage];
    } else if ([self isEndToHead]) {
        [self p_processEndToHeadStage:stage];
    } else {
        CJPayLogAssert(NO, @"不能处理的查找方法");
    }
}

- (void)uploadEvents:(void (^)(NSArray<NSDictionary *> *events))uploadBlock {
    CJ_CALL_BLOCK(uploadBlock, self.events);
}

- (void)p_processHeadToEndStage:(CJPayPerformanceStage *)stage {
    // 因为是从前往后进行匹配，所以首先判断HeadStage是否为空，1. 如果为空则先找headStage  2. 如果非空，则尝试找endStage  3. 在找到两个stage之后，则可以认为能够完成一次独立的计算，此时计算后将事件填充到events数组里，同时将headStage和endStage清空继续查找同一个流程下的下一个值。
    if (!self.headStage) {
        if ([self.headNode matchToPerformanceStage:stage]) {
            self.headStage = stage;
        }
    } else {
        if ([self.endNode matchToPerformanceStage:stage]) {
            self.endStage = stage;
            // 在headStage和endStage都找到后，进行事件的计算和重置处理
            [self p_caculateEventAndReset];
        }
    }
}

- (void)p_processEndToHeadStage:(CJPayPerformanceStage *)stage {
    // 该过程同从前往后找的方式正好相反
    if (!self.endStage) {
        if ([self.endNode matchToPerformanceStage:stage]) {
            self.endStage = stage;
        }
    } else {
        if ([self.headNode matchToPerformanceStage:stage]) {
            self.headStage = stage;
            // 在headStage和endStage都找到后，进行事件的计算和重置处理
            [self p_caculateEventAndReset];
        }
    }
}

- (void)p_caculateEventAndReset {
    NSMutableDictionary *uploadEventDic = [NSMutableDictionary new];
    
    NSString *eventName = self.mapToEventName;
    if (!Check_ValidString(eventName)) {
        eventName = [NSString stringWithFormat:@"%@$$%@", self.headStage.name, self.endStage.name];
    }
    [uploadEventDic cj_setObject:eventName forKey:@"process_event_name"];
    [uploadEventDic cj_setObject:@(self.endStage.curTime - self.headStage.curTime) forKey:@"time"]; // 这里的字段名称需要更改才行
    [uploadEventDic cj_setObject:@((self.endStage.curTime - self.headStage.curTime) * 1000) forKey:@"time_ms"];
    [uploadEventDic cj_setObject:self.headStage.sdkProcessID forKey:@"head_process_id"];
    [uploadEventDic cj_setObject:self.endStage.sdkProcessID forKey:@"end_process_id"];
    if (self.headNode.need_extra) {
        [uploadEventDic cj_setObject:self.headStage.extra forKey:@"head_extra"];
    }
    if (self.endNode.need_extra) {
        [uploadEventDic cj_setObject:self.endStage.extra forKey:@"end_extra"];
    }
    [self.events addObject:[uploadEventDic copy]];
    
    self.headStage = nil;
    self.endStage = nil;
}

#pragma - mark assoiate object
- (NSMutableArray *)events {
    NSMutableArray *eventArray = objc_getAssociatedObject(self, @selector(events));
    if (!eventArray) {
        eventArray = [NSMutableArray new];
        objc_setAssociatedObject(self, @selector(events), eventArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return eventArray;
}

- (void)setHeadStage:(CJPayPerformanceStage *)headStage {
    objc_setAssociatedObject(self, @selector(headStage), headStage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CJPayPerformanceStage *)headStage {
    return objc_getAssociatedObject(self, @selector(headStage));
}

- (void)setEndStage:(CJPayPerformanceStage *)endStage {
    objc_setAssociatedObject(self, @selector(endStage), endStage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (CJPayPerformanceStage *)endStage {
    return objc_getAssociatedObject(self, @selector(endStage));
}

@end

@implementation CJPayPerformanceMonitorModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"uploadRules" : @"event_upload_rules",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
