//
//  BDTuringEventService.m
//  BDTuring
//
//  Created by bob on 2019/9/18.
//

#import "BDTuringEventService.h"
#import "BDTuringServiceCenter.h"

#import "BDTuringUtility.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringMacro.h"
#import "NSObject+BDTuring.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTNetworkManager.h"
#import "BDTuringEventConstant.h"

#import <UIKit/UIKit.h>
#import <pthread/pthread.h>

@interface BDTuringEventService ()

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *touchEvents;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) NSTimeInterval lastSamplingTimeInterval;

@end

static double samplingInterval = 1.0/30.0; //sampling with 30Hz,use x.0 to get float value

@implementation BDTuringEventService

+ (instancetype)sharedInstance {
    static BDTuringEventService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void)dealloc {
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.serialQueue = dispatch_queue_create("com.BDTuring.Event", DISPATCH_QUEUE_SERIAL);
        self.touchEvents = [NSMutableArray new];
        NSString *path = turing_sdkDatabaseFile();
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    
    return self;
}

#pragma mark - Action Event

- (void)collectEvent:(NSString *)event data:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length < 1) {
        return;
    }
    
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.config.appID forKey:BDTuringEventParamHostAppID];
    [data setValue:event forKey:BDTuringEventParamKey];
    [data setValue:BDTuringEventParamTuring forKey:BDTuringEventParamSpecial];
    if ([params isKindOfClass:[NSDictionary class]]) {
        [data addEntriesFromDictionary:params];
    }
    
    data = [self paramCheck:data];
    
    [self nativeCollectEvent:BDTuringEventName data:data];
}

- (void)h5CollectEvent:(NSString *)event data:(NSDictionary *)params {
    if (![event isKindOfClass:[NSString class]] || event.length < 1) {
        return;
    }
    if (![event containsString:@"turing_verify"]) {
        event = [NSString stringWithFormat:@"%@%@",@"turing_verify_",event];
        [params setValue:event forKey:BDTuringEventParamEvent];
    }
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.config.appID forKey:BDTuringEventParamHostAppID];
    [data setValue:BDTuringEventParamTuring forKey:BDTuringEventParamSpecial];
    [data setValue:BDTuringSDKVersion forKey:BDTuringEventParamSdkVersion];
    if ([params isKindOfClass:[NSDictionary class]]) {
        [data addEntriesFromDictionary:params];
    }
    data = [self paramCheck:data];
    [self nativeCollectEvent:event data:data];
}

- (NSMutableDictionary *)paramCheck:(NSMutableDictionary *)param {
    id custom = [param valueForKey:BDTuringEventParamCustom];
    if (custom != nil) {
        if ([custom isKindOfClass:[NSString class]]) {
            NSMutableString *customStr = [(NSString *)custom mutableCopy];
            if ([customStr length] >= 1000) {
                customStr = [customStr substringToIndex:1000];
                [param setValue:customStr forKey:BDTuringEventParamCustom];
            }
        }
    }
    return param;
}

/// async to avoid jam
- (void)nativeCollectEvent:(NSString *)event data:(NSDictionary *)params {
    dispatch_async(self.serialQueue, ^{
        [BDTNetworkManager uploadEvent:event param:params];
    });
}

- (void)collectTouchEvents:(NSArray<NSMutableDictionary *> *)events {
    if (events.count < 1) {
        return;
    }
    
    NSMutableDictionary *data = [self.config eventParameters] ?: [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    [data setValue:@(turing_currentIntervalMS()) forKey:kBDTuringTime];
    [data setValue:@"touch_event" forKey:kBDTuringEvent];
    [data setValue:BDTuringEventKeyWord forKey:kBDTuringEventKeyWord];
    
    NSMutableArray<NSDictionary *> *touchEvents = [NSMutableArray arrayWithCapacity:events.count];
    
    [events enumerateObjectsUsingBlock:^(NSMutableDictionary *event, NSUInteger idx, BOOL *stop) {
        [event addEntriesFromDictionary:data];
        [touchEvents addObject:event];
    }];
    
    [self.touchEvents addObjectsFromArray:touchEvents];
}

- (NSArray *)fetchTouchEvents {
    NSArray<NSDictionary *> *events = [self.touchEvents copy];
    self.touchEvents = [NSMutableArray new];
    
    return events;
}

- (void)clearAllTouchEvents {
    self.touchEvents = [NSMutableArray new];
}

/// move phase 1/5
- (void)collectTouchEventsFromEvent:(UIEvent *)event {
    //mobile support 10-finger-multiple touch most
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:10];
    NSMutableArray *testresult = [NSMutableArray arrayWithCapacity:10];
    BOOL shouldUpload = (event.timestamp - self.lastSamplingTimeInterval >= samplingInterval);
    for (UITouch *obj in event.allTouches) {
        UITouchPhase phase = obj.phase;
        if (phase == UITouchPhaseMoved) {
            if (shouldUpload) {
                //update sampling timestamp
                self.lastSamplingTimeInterval = event.timestamp;
            } else {
                //this is move touch, but should not be collected
                continue;
            }
        }
        
        NSDictionary *touchDic = [self toucheventFromTouch:obj];
        if (touchDic.count > 0) {
            [result addObject:touchDic];
        }
    }
    
    if (result.count > 0) {
        [self collectTouchEvents:result];
    }
}

- (NSMutableDictionary *)toucheventFromTouch:(UITouch *)touch {
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:BDTuringDictionaryCapacityLarge];
    if (@available(iOS 9.0, *)) {
        dic[kBDTuringTouchForceTouch] = @(touch.view.traitCollection.forceTouchCapability);
        dic[kBDTuringTouchForce] = @(touch.force);
    }

    dic[kBDTuringTouchTimestamp] = @((long long)(touch.timestamp * 1000));
    dic[kBDTuringTouchMajorRadius] = @(touch.majorRadius);
    dic[kBDTuringTouchPhase] = @(touch.phase);
    CGPoint loc = [touch locationInView:touch.window];
    dic[kBDTuringTouchX] = @(loc.x);
    dic[kBDTuringTouchY] = @(loc.y);

    return dic;
}

@end
