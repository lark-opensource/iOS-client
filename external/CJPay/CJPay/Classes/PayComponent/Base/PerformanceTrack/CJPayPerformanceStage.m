//
//  CJPayPerformanceStage.m
//  Pods
//
//  Created by 王新华 on 2021/10/15.
//

#import "CJPayPerformanceStage.h"
#import "CJPaySDKMacro.h"

@interface CJPayPerformanceStage()
@property (nonatomic, copy, readwrite) NSString *stageTypeStr;

@end

@implementation CJPayPerformanceStage

- (void)setStageType:(CJPayPerformanceStageType)stageType {
    _stageType = stageType;
}

+ (NSString *)stageTypeStrByENUM:(CJPayPerformanceStageType)type {
    NSString *typeStr = @"";
    switch (type) {
        case CJPayPerformanceStageTypeNone:
            typeStr = @"";
            break;
        case CJPayPerformanceStageTypeAPIStart:
            typeStr = @"api_start";
            break;
        case CJPayPerformanceStageTypeAPIEnd:
            typeStr = @"api_end";
            break;
        case CJPayPerformanceStageTypeRequestStart:
            typeStr = @"request_start";
            break;
        case CJPayPerformanceStageTypeRequestEnd:
            typeStr = @"request_end";
            break;
        case CJPayPerformanceStageTypePageInit:
            typeStr = @"page_init";
            break;
        case CJPayPerformanceStageTypePageAppear:
            typeStr = @"page_appear";
            break;
        case CJPayPerformanceStageTypePageFinishRender:
            typeStr = @"page_finish_render";
            break;
        case CJPayPerformanceStageTypePageDisappear:
            typeStr = @"page_disappear";
            break;
        case CJPayPerformanceStageTypePageDealloc:
            typeStr = @"page_dealloc";
            break;
        case CJPayPerformanceStageTypeActionBtn:
            typeStr = @"action_btn";
            break;
        case CJPayPerformanceStageTypeActionCell:
            typeStr = @"action_cell";
            break;
        case CJPayPerformanceStageTypeActionGesture:
            typeStr = @"action_gesture";
            break;
            
        default:
            break;
    }
    return typeStr;
}

- (BOOL)isValid {
    return Check_ValidString(self.name) && self.curTime > 0 && self.stageType != CJPayPerformanceStageTypeNone;
}

- (BOOL)isEqual:(id)object {
    return [[self description] isEqualToString:[object description]];
}

- (NSUInteger)hash {
    return [[self description] hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{ name = %@, cur_time = %f, sdk_process_id = %@, page_name = %@, stage_type = %@, extra = %@ }",self.name, self.curTime, self.sdkProcessID, self.pageName, [self.class stageTypeStrByENUM:self.stageType], self.extra];
}

@end
