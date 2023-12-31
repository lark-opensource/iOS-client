//
//  ACCEditorTrackerTool.m
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2020/11/9.
//

#import "ACCEditorTrackerTool.h"
#import <CreationKitArch/ACCTimeTraceUtil.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCFeatureComponent.h>

NSString * const kAWEEditorEventFirstFrame = @"first_frame_duration";
NSString * const kAWEEditorEventPreControlerInit = @"pre_controller_init_cost";
NSString * const kAWEEditorEventControlerInit = @"controller_init_cost";
NSString * const kAWEEditorEventViewDidLoad = @"view_did_load_cost";
NSString * const kAWEEditorEventViewWillAppear = @"view_will_appear_cost";
NSString * const kAWEEditorEventViewAppear = @"view_appear_cost";
NSString * const kAWEEditorEventCreatePlayer = @"create_player_cost";
NSString * const kAWEEditorEventPlayerFirstFrame = @"player_first_frame_cost";
NSString * const kAWEEditorEventPageLoadUI = @"page_load_ui_cost";

@interface ACCEditorTrackerTool()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *traceTimeDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary*> *componentTimeDic;
@property (nonatomic, strong) ACCEditorTrackerTool *editorTrackerTool;
@property (nonatomic, assign) BOOL hasReportFirstFrameDuration;

@end

@implementation ACCEditorTrackerTool

- (instancetype)init
{
    self = [super init];
    if (self) {
        _traceTimeDic = [NSMutableDictionary new];
        _componentTimeDic = [NSMutableDictionary new];
    }
    return self;
}

- (void)startTraceTimeForKey:(NSString *)key
{
    [ACCTimeTraceUtil startTraceTimeForKey:key];
}

- (void)stopTraceTimeForKey:(NSString *)key
{
    if (key.length > 0) {
        NSTimeInterval interval = [ACCTimeTraceUtil timeIntervalForKey:key];
        [ACCTimeTraceUtil cancelTraceTimeForKey:key];
        if (!self.traceTimeDic[key]) {
            self.traceTimeDic[key] = @(interval);
        }
    }
}

- (void)addTrackTime:(NSTimeInterval)interval key:(NSString *)key
{
    if (key.length > 0 && !self.traceTimeDic[key]) {
        self.traceTimeDic[key] = @(interval);
    }
}

- (NSDictionary *)trackerDic
{
    NSMutableDictionary *params = [self.traceTimeDic mutableCopy];
    [params addEntriesFromDictionary:self.componentTimeDic ? @{@"component":self.componentTimeDic} : @{}];
    return [params copy];
}

- (void)cleanTraceTime
{
    self.traceTimeDic = [NSMutableDictionary new];
    self.componentTimeDic = [NSMutableDictionary new];
}

- (void)trackPlayerFirstFrameRenderIfNeed:(NSDictionary *)params
{
    if (self.hasReportFirstFrameDuration) {
        return;
    }
    self.hasReportFirstFrameDuration = YES;
    NSMutableDictionary *totalParams = params ? [params mutableCopy] : [NSMutableDictionary new];
    [totalParams addEntriesFromDictionary:self.trackerDic ?: @{}];
    
    //add new sub event
    NSMutableDictionary *trackParams = totalParams ? totalParams.mutableCopy:[NSMutableDictionary new];
    if (trackParams[kAWEEditorEventFirstFrame] && trackParams[kAWEEditorEventPlayerFirstFrame] && trackParams[kAWEEditorEventPageLoadUI]) {
        NSTimeInterval withOutPlayer = [trackParams[kAWEEditorEventFirstFrame] doubleValue] - [trackParams[kAWEEditorEventPlayerFirstFrame] doubleValue] + [trackParams[kAWEEditorEventPageLoadUI] doubleValue];
        trackParams[@"first_frame_duration_without_player"] = @(withOutPlayer);
    }
    //track
    [ACCTracker() trackEvent:@"tool_performance_edit_first_frame" params:trackParams.copy needStagingFlag:NO];
    
    //monitor
    totalParams[@"service"] = @"tool_performance_edit_first_frame";
    [ACCMonitor() trackData:totalParams logTypeStr:@"dmt_studio_performance_log"];
    [self.editorTrackerTool cleanTraceTime];
}

#pragma mark - ACCComponentLogDelegate

- (void)logComponent:(id<ACCFeatureComponent>)component selector:(SEL)aSelector duration:(NSTimeInterval)duration
{
    if (component) {
        NSString *componentKey = NSStringFromClass([component class]);
        NSMutableDictionary *valueDic = self.componentTimeDic[componentKey];
        if (!valueDic) {
            valueDic = [NSMutableDictionary new];
            self.componentTimeDic[componentKey] = valueDic;
        }
        NSString *valueKey = NSStringFromSelector(aSelector);
        if (valueKey && !valueDic[valueKey]) {
            valueDic[valueKey] = @(duration);
        }
    }
}

@end
