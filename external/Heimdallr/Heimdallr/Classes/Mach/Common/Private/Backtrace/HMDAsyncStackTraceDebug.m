//
//  HMDAsyncStackTraceDebug.m
//  Pods
//
//  Created by yuanzhangjing on 2019/11/11.
//

#import "HMDAsyncStackTraceDebug.h"

#pragma mark - debug

#if enable_time_profile
static double runloop_begin;
static double runloop_end;

static void update_statistics_result_t(_statistics_result_t *s,double time_cost) {
    s->avg_cost = ((s->avg_cost * s->sample_count) + time_cost)/(s->sample_count+1);
    s->max_cost = MAX(s->max_cost, time_cost);
    s->sample_count++;
}

static void print_statistics_result_t(const char *tag, _statistics_result_t *s,double time_cost) {
    printf("[main:%d] %s : cost=%.3fms [avg=%.3fms max=%.3fms count=%llu]\n",
           pthread_main_np()!=0,tag,time_cost,s->avg_cost,
           s->max_cost,
           s->sample_count);
}

void runloopBegin(void) {
    runloop_begin = CACurrentMediaTime();
}

void runloopEnd(void) {
    if (runloop_begin <=0) {
        memset(&statistics_main_thread, 0, sizeof(statistics_main_thread));
        return;
    }
    runloop_end = CACurrentMediaTime();
        
    double record = statistics_main_thread.record_cost;
    
    double insert = statistics_main_thread.insert_cost;
    
    double remove = statistics_main_thread.remove_cost;
    
    double time_cost = (record + insert + remove);

    statistics_result_main_thread.duration += (runloop_end - runloop_begin)*1000;
    statistics_result_main_thread.max_cost = MAX(statistics_result_main_thread.max_cost, time_cost);
    if (statistics_main_thread.record_times > 0 || statistics_main_thread.insert_times > 0 || statistics_main_thread.remove_times > 0) {
        statistics_result_main_thread.avg_cost = (statistics_result_main_thread.avg_cost * statistics_result_main_thread.sample_count + time_cost)/(statistics_result_main_thread.sample_count + 1);
        statistics_result_main_thread.sample_count++;
    }

    printf("runloop : dur=%.3fms cost=%.3fms record=%.3fms(%d) insert=%.3fms(%d) remove=%.3fms(%d)\n[avg=%.3fms max=%.3fms count=%llu dur=%.3fms]\n",
           (runloop_end - runloop_begin)*1000,time_cost,
           record,statistics_main_thread.record_times,
           insert,statistics_main_thread.insert_times,
           remove,statistics_main_thread.remove_times,
           statistics_result_main_thread.avg_cost,
           statistics_result_main_thread.max_cost,
           statistics_result_main_thread.sample_count,
           statistics_result_main_thread.duration);
        
    memset(&statistics_main_thread, 0, sizeof(statistics_main_thread));
}

static CFRunLoopActivity last_activity;
void runloopCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    CFRunLoopActivity last = last_activity;
    last_activity = activity;
    switch (activity) {
        case kCFRunLoopEntry:
            runloopBegin();
            break;
            
        case kCFRunLoopBeforeTimers:

            break;
            
        case kCFRunLoopBeforeSources:
            if (last != kCFRunLoopAfterWaiting && last != kCFRunLoopBeforeTimers) {
                runloopBegin();
            }
            break;
            
        case kCFRunLoopAfterWaiting:
            runloopBegin();
            break;
        case kCFRunLoopBeforeWaiting:
            runloopEnd();
            break;
        case kCFRunLoopExit:
            runloopEnd();
            break;
            
        default:
            break;
    }
}

void addRunLoopObserver(void) {
    CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
    CFRunLoopObserverContext context = {0, NULL, NULL, NULL, NULL};
    CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, LONG_MIN, &runloopCallback, &context);
    
    CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
}

@interface NSObject (HMDAsyncTraceObserver)

@end
@implementation NSObject (HMDAsyncTraceObserver)

static CADisplayLink *_displayLink;
- (void)start_timer {
    _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                    selector:@selector(updateFPS)];
    if (@available(iOS 10.0, *)) {
        _displayLink.preferredFramesPerSecond = 60;
    } else {
        _displayLink.frameInterval = 1;
    }
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    _displayLink.paused = NO;
}

- (void)updateFPS {
    static double last_timestamp;
    if (last_timestamp == 0) {
        last_timestamp = _displayLink.timestamp;
        return;
    }
    double record = statistics_main_thread.record_cost;
    
    double insert = statistics_main_thread.insert_cost;
    
    double remove = statistics_main_thread.remove_cost;
    
    double time_cost = (record + insert + remove);
    
    statistics_result_main_thread.duration += (_displayLink.timestamp - last_timestamp)*1000;
    statistics_result_main_thread.max_cost = MAX(statistics_result_main_thread.max_cost, time_cost);
    statistics_result_main_thread.avg_cost = (statistics_result_main_thread.avg_cost * statistics_result_main_thread.sample_count + time_cost)/(statistics_result_main_thread.sample_count + 1);
    statistics_result_main_thread.sample_count++;

    printf("display link : dur=%.3fms cost=%.3fms record=%.3fms(%d) insert=%.3fms(%d) remove=%.3fms(%d)\n[avg=%.3fms max=%.3fms count=%llu dur=%.3fms]\n",
           (_displayLink.timestamp - last_timestamp)*1000,time_cost,
           record,statistics_main_thread.record_times,
           insert,statistics_main_thread.insert_times,
           remove,statistics_main_thread.remove_times,
           statistics_result_main_thread.avg_cost,
           statistics_result_main_thread.max_cost,
           statistics_result_main_thread.sample_count,
           statistics_result_main_thread.duration);
    
    last_timestamp = _displayLink.timestamp;
    
    memset(&statistics_main_thread, 0, sizeof(statistics_main_thread));
}

@end

void addTimer(void) {
    static NSObject *obj;
    obj = [[NSObject alloc] init];
    [obj start_timer];
}


#endif
