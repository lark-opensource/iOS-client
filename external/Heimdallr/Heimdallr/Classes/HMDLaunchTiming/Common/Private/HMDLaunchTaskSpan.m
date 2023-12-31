//
//  HMDLaunchStageInfo.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/6/22.
//

#import "HMDLaunchTaskSpan.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDLaunchTaskSpan

+ (instancetype)defaultWithName:(NSString *)name start:(long long)start end:(long long)end {
    HMDLaunchTaskSpan *stage = [[HMDLaunchTaskSpan alloc] init];
    stage.name = name;
    stage.start = start;
    stage.end = end;
     stage.module = kHMDLaunchTimingDefaultSpanModule;
    return stage;
}

+ (NSArray<HMDLaunchTaskSpan *> *)defaultSpansWithTimingStruct:(HMDLaunchTimingStruct)timing
                                                   endTaskName:(NSString *)endTaskName {
    NSMutableArray *spansArr = [NSMutableArray array];
    // exec to load cls
    if (timing.proc_exec > 0
        && timing.cls_load > 0
        && timing.cls_load >= timing.proc_exec) {
        HMDLaunchTaskSpan *execToLoad = [HMDLaunchTaskSpan defaultWithName:kHMDLaunchTimingSpanFromExecToLoad start:timing.proc_exec end:timing.cls_load];
        [spansArr hmd_addObject:execToLoad];
    }

    if (timing.cls_load > 0
        && timing.finish_launch > 0
        && timing.finish_launch >= timing.cls_load) {
        HMDLaunchTaskSpan *loadTolaunch = [HMDLaunchTaskSpan defaultWithName:kHMDLaunchTimingSpanFromLoadToFinishLaunch start:timing.cls_load end:timing.finish_launch];
        [spansArr hmd_addObject:loadTolaunch];
    }

    if (timing.finish_launch > 0
        && timing.first_render > 0
        && timing.first_render >= timing.finish_launch) {
        HMDLaunchTaskSpan *launchToRender =
            [HMDLaunchTaskSpan defaultWithName:kHMDLaunchTimingSpanFromFishLaunchToRender start:timing.finish_launch end:timing.first_render];
        [spansArr hmd_addObject:launchToRender];
    }

    if (timing.user_finish > 0
        && timing.first_render > 0
        && timing.user_finish >= timing.first_render) {
        NSString *stageName = [NSString stringWithFormat:@"firstrender_to_%@", endTaskName ?: kHMDLaunchTimingDefaultCustomEndName];
        HMDLaunchTaskSpan *renderToEnd = [HMDLaunchTaskSpan defaultWithName:stageName start:timing.first_render end:timing.user_finish];
        [spansArr hmd_addObject:renderToEnd];
    }
    return [spansArr copy];
}

@end

#pragma mark ---- HMDLaunchTimingRecord Category
@implementation HMDLaunchTraceTimingInfo


@end

#pragma mark ---- HMDLaunchTimingRecord Category
@implementation HMDLaunchTimingRecord (LaunchStage)

- (void)hmd_insertTraceModel:(HMDLaunchTraceTimingInfo *)timing {
    NSMutableDictionary *traceData = [NSMutableDictionary dictionary];
    NSMutableArray *spans = [NSMutableArray array];
    for (HMDLaunchTaskSpan *taskSpan in timing.taskSpans) {
        NSDictionary *stageSpan = @{
            kHMDLaunchTimingKeyModuleName: taskSpan.module?:@"null",
            kHMDLaunchTimingKeySpanName: taskSpan.name?:@"-",
            kHMDLaunchTimingKeyStart: @(taskSpan.start),
            kHMDlaunchTimingKeyEnd: @(taskSpan.end),
            kHMDLaunchTimingKeyThread: taskSpan.isSubThread?@"other":@"main"
        };
        [spans addObject:stageSpan];
    }

    [traceData setValue:timing.name forKey:kHMDLaunchTimingKeyName];
    [traceData setValue:timing.pageType forKey:kHMDLaunchTimingKeyPageType];
    [traceData setValue:@(timing.start) forKey:kHMDLaunchTimingKeyStart];
    [traceData setValue:@(timing.end) forKey:kHMDlaunchTimingKeyEnd];
    [traceData setValue:@(timing.collectFrom) forKey:kHMDLaunchTimingKeyCollectFrom];
    [traceData setValue:timing.pageName forKey:kHMDLaunchTimingKeyPageName];
    [traceData setValue:@(timing.prewarm) forKey:kHMDLaunchTimingKeyPrewarm];
    if (timing.customLaunchModel && timing.customLaunchModel.length > 0) {
        [traceData setValue:timing.customLaunchModel forKey:kHMDLaunchTimingKeyCustomModel];
    }
    if (spans && spans.count > 0) {
        [traceData setValue:[spans copy] forKey:kHMDLaunchTimingKeySpans];
    }
    if ([NSJSONSerialization isValidJSONObject:traceData]) {
        self.trace = traceData;
    }
}


@end
