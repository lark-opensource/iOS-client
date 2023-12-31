//
//  OKStartUpScheduler.m
//  OKStartUp
//
//  Created by bob on 2020/1/13.
//

#import "OKStartUpScheduler.h"
#import "OKStartUpTask+Private.h"
#import "OKInternalTask.h"

@interface OKStartUpScheduler ()

@property (nonatomic, strong) NSMutableArray<OKStartUpTask *> *tasks;
@property (strong, nonatomic) dispatch_queue_t asyncqueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *taskTimeStamps;


@property (nonatomic, strong) NSArray<NSString *> *syncIdentifiers;
@property (nonatomic, strong) NSMutableArray<OKStartUpTask *> *syncTasks;

@property (nonatomic, strong) OKStartUpTask *rangersAppLogStartUpTask;

@end

@implementation OKStartUpScheduler

+ (instancetype)sharedScheduler {
    static OKStartUpScheduler *scheduler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scheduler = [self new];
    });

    return scheduler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.asyncqueue = dispatch_queue_create("com.onekit.start", DISPATCH_QUEUE_SERIAL);
        self.tasks = [NSMutableArray new];
        self.syncTasks = [NSMutableArray new];
        self.taskTimeStamps = [NSMutableDictionary new];
    }
    
    return self;
}
#pragma mark -  Tasks


+ (void)setSyncTaskIdentifiers:(NSArray<NSString *> *)identfiers
{
    [[self sharedScheduler] setSyncIdentifiers:identfiers];
}

- (void)addTask:(OKStartUpTask *)task {
    if (task == nil) {
        return;
    }
    
    if ([task.taskIdentifier isEqualToString:@"RangersAppLogStartUpTask"]) {
        self.rangersAppLogStartUpTask = task;
        return;
    }
    
    if (self.syncIdentifiers && [self.syncIdentifiers containsObject:task.taskIdentifier]) {
        [self.syncTasks addObject:task];
        return;
    }
    
    dispatch_async(self.asyncqueue, ^{
        [self.tasks addObject:task];
    });
}

- (NSMutableArray<OKStartUpTask *> *)sortedTasks {
    NSMutableArray<OKStartUpTask *> *tasks = self.tasks;
    [tasks sortUsingComparator:^NSComparisonResult (OKStartUpTask * obj1, OKStartUpTask *obj2) {
        if (obj1.priority > obj2.priority) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
    
    return tasks;
}

- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [[OKInternalTask new] _privateStartWithLaunchOptions:launchOptions];
    
    if (self.rangersAppLogStartUpTask) {
        [self.rangersAppLogStartUpTask _privateStartWithLaunchOptions:launchOptions];
    }
    
    if (self.syncIdentifiers) {
        for (OKStartUpTask *task in self.syncTasks) {
            [task _privateStartWithLaunchOptions:launchOptions];
        }
    }
    
    dispatch_async(self.asyncqueue, ^{
        NSMutableArray<OKStartUpTask *> *tasks = [self sortedTasks];
        for (OKStartUpTask *task in tasks) {
            [task _privateStartWithLaunchOptions:launchOptions];
        }
    });
}

@end
