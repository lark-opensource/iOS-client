//
//  BDDYCSessionTask.m
//  BDDynamically
//
//  Created by zuopengliu on 13/3/2018.
//

#import "BDDYCSessionTask.h"



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

#pragma mark - BDDYCModuleListSessionTask

@interface BDDYCModuleListSessionTask ()
@property (nonatomic, strong) id task;
@end

@implementation BDDYCModuleListSessionTask

@synthesize cancelled = _cancelled;
@synthesize error = _error;
@synthesize retryTasks = _retryTasks;

- (instancetype)initWithURLTask:(id )urlTask;
{
    if ((self = [super init])) {
        _task = urlTask;
        _cancelled = NO;
    }
    return self;
}

- (void)cancel
{
    if ([_task isKindOfClass:[TTHttpTask class]]) {
        TTHttpTask *task = (TTHttpTask *)_task;
        [task cancel];
    } else if ([_task isKindOfClass:[NSURLSessionDataTask class]]) {
        NSURLSessionDataTask *task = (NSURLSessionDataTask *)_task;
        [task cancel];
    } else {
//        NSAssert(<#condition#>, <#desc, ...#>)
    }
    
    NSArray *tasks;
    @synchronized(self.retryTasks) {
        tasks = [self.retryTasks copy];
    };
    [tasks enumerateObjectsUsingBlock:^(id<BDDYCSessionTask> obj, NSUInteger idx, BOOL *stop) {
        [obj cancel];
    }];
    _cancelled = YES;
}

@end

#pragma mark -

@interface BDDYCModuleSessionTask ()
@property (nonatomic, strong) NSURLSessionTask *task;
@end

@implementation BDDYCModuleSessionTask : NSObject

@synthesize cancelled = _cancelled;
@synthesize error = _error;
@synthesize retryTasks = _retryTasks;

- (instancetype)initWithURLTask:(NSURLSessionTask *)urlTask;
{
    if ((self = [super init])) {
        _task = urlTask;
        _cancelled = NO;
    }
    return self;
}

- (void)cancel
{
    [_task cancel];
    
    NSArray *tasks;
    @synchronized(self.retryTasks) {
        tasks = [self.retryTasks copy];
    };
    [tasks enumerateObjectsUsingBlock:^(id<BDDYCSessionTask> obj, NSUInteger idx, BOOL *stop) {
        [obj cancel];
    }];
    _cancelled = YES;
}

@end

#pragma mark - BDDYCSessionTask

@interface BDDYCSessionTask ()
@property (nonatomic, strong) NSMutableDictionary<id, BDDYCModuleSessionTask *> *moduleTaskMapper;
@end

@implementation BDDYCSessionTask

@synthesize cancelled = _cancelled;
@synthesize error = _error;
@synthesize retryTasks = _retryTasks;

- (void)dealloc
{
    [self cancel];
    [self.moduleTaskMapper removeAllObjects];
}

- (BDDYCModuleSessionTask *)taskForModuleModel:(id<NSCopying>)aModule
{
    if (!aModule) return nil;
    
    NSDictionary<id, id<BDDYCSessionTask>> *mapper;
    @synchronized(self.moduleTaskMapper) {
        mapper = [self.moduleTaskMapper copy];
    };
    return mapper[aModule];
}

- (void)addModuleTask:(id<BDDYCSessionTask>)task forModuleModel:(id<NSCopying>)aModule
{
    if (!task || !aModule) return;
    self.moduleTaskMapper[aModule] = task;
}

- (void)cancelTaskForModuleModel:(id<NSCopying>)aModule
{
    if (!aModule) return;
    id<BDDYCSessionTask> task;
    @synchronized(self.moduleTaskMapper) {
        task = self.moduleTaskMapper[aModule];
    };
    [task cancel];
}

- (void)cancel
{
    __block BOOL cancelled = YES;
    @synchronized(self.moduleListTask) {
        [_moduleListTask cancel];
        cancelled = cancelled && [_moduleListTask isCancelled];
    };
    
    NSArray<id<BDDYCSessionTask>> *list;
    @synchronized(self.moduleTaskMapper) {
        list = [self.moduleTaskMapper allValues];
    };
    [list enumerateObjectsUsingBlock:^(id<BDDYCSessionTask> obj, NSUInteger idx, BOOL *stop) {
        [obj cancel];
        cancelled = cancelled && [obj isCancelled];
    }];
    
    NSArray *tasks;
    @synchronized(self.retryTasks) {
        tasks = [self.retryTasks copy];
    };
    [tasks enumerateObjectsUsingBlock:^(id<BDDYCSessionTask> obj, NSUInteger idx, BOOL *stop) {
        [obj cancel];
        cancelled = cancelled && [obj isCancelled];
    }];
    _cancelled = cancelled;
}

- (NSArray<id<BDDYCSessionTask>> *)moduleTasks
{
    return [_moduleTaskMapper allValues];
}

- (NSMutableDictionary<id, BDDYCModuleSessionTask *> *)moduleTaskMapper
{
    if (!_moduleTaskMapper) {
        _moduleTaskMapper = [NSMutableDictionary dictionary];
    }
    return _moduleTaskMapper;
}

@end

#pragma clang diagnostic pop
