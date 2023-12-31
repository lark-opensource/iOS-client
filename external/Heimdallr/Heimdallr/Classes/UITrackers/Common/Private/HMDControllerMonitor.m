//
//  HMDControllerMonitor.m
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import "HMDControllerMonitor.h"

static HMDControllerMonitor *shared = nil;

@interface HMDControllerMonitor()
@property (nonatomic, strong) dispatch_queue_t pageQueue;
@property (nonatomic, strong) NSMutableDictionary *pageTimeDictionary;
@end

@implementation HMDControllerMonitor

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [super init];
    });
    return shared;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [super allocWithZone:zone];
    });
    return shared;
}

//the blockList of ViewController 
- (NSArray *)getControllerMonitorBlockList {
    NSArray *blockList = @[@"UINavigationController",
                           @"UIViewController",
                           @"UITabBarController"];
    return blockList;
}

- (void)addControllerMonitorWithPageName:(NSString *)pageName methodSelector:(NSString *)selectorName timeInterval:(NSTimeInterval)interval isFirstOpen:(NSInteger)isFirstOpen {
    if ([[self getControllerMonitorBlockList] containsObject:pageName]) {
        return;
    }
    
    if ([(id)self.delegate respondsToSelector:@selector(hmdControllerName:typeName:timeInterval:isFirstOpen:)]) {
        [self.delegate hmdControllerName:pageName typeName:selectorName timeInterval:interval isFirstOpen:isFirstOpen];
    }
}

//- (void)addControllerMonitorWithViewControllerTimeStamp:(NSTimeInterval)timeStamp pageName:(NSString *)pageName state:(HMDControllerMonitorState)state typeName:(NSString *)typeName {
//    if (!self.pageQueue) {
//        NSString *label = @"com.hmdpagemonitor.pagequeue";
//        self.pageQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
//    }
//    if (self.pageQueue) {
//        // 串行、异步
//        dispatch_async(self.pageQueue, ^{
//            [self addControllerTimeStamp:timeStamp pageName:pageName state:state typeName:typeName];
//        });
//    }
//}
//- (void)addControllerTimeStamp:(NSTimeInterval)timeStamp pageName:(NSString *)pageName state:(HMDControllerMonitorState)state typeName:(NSString *)typeName {
//    if ([[self getControllerMonitorBlockList] containsObject:pageName]) {
//        return;
//    }
//    if (!self.pageTimeDictionary) {
//        self.pageTimeDictionary = [NSMutableDictionary new];
//    }
//    if (self.pageTimeDictionary && [self.pageTimeDictionary isKindOfClass:[NSMutableDictionary class]]) {
//        if (state == HMDControllerMonitorStateStart) {
//            [self.pageTimeDictionary setObject:@(timeStamp) forKey:pageName];
//        }
//        if ([self.pageTimeDictionary.allKeys containsObject:pageName] && typeName) {
//            if (state == HMDControllerMonitorStateMiddleAction) {
//                NSTimeInterval pageTotalTime = timeStamp - [[self.pageTimeDictionary valueForKey:pageName] doubleValue];
//                if ([(id)self.delegate respondsToSelector:@selector(hmdControllerName:typeName:timeInterval:)]) {
//                    [self.delegate hmdControllerName:pageName typeName:typeName timeInterval:pageTotalTime];
//                }
//            }
//            if (state == HMDControllerMonitorStateEnd) {
//                NSTimeInterval pageTotalTime = timeStamp - [[self.pageTimeDictionary valueForKey:pageName] doubleValue];
//                if ([(id)self.delegate respondsToSelector:@selector(hmdControllerName:typeName:timeInterval:)]) {
//                    [self.delegate hmdControllerName:pageName typeName:typeName timeInterval:pageTotalTime];
//                }
//                [self.pageTimeDictionary removeObjectForKey:pageName];
//            }
//        }
//    }
//}
@end
