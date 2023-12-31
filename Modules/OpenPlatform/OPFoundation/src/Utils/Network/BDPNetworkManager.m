//
//  BDPNetworkManager.m
//  Timor
//
//  Created by liubo on 2018/11/19.
//

#import "BDPNetworkManager.h"

@interface BDPNetworkManager ()
@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL removeEarliest;
@end

@implementation BDPNetworkManager

+ (instancetype)defaultManager {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [[BDPNetworkManager alloc] initWithMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount removeEarliest:NO];
}

- (instancetype)initWithMaxConcurrentOperationCount:(NSInteger)maxCount removeEarliest:(BOOL)removeEarliest {
    if ((self = [super init])) {
        self.maxConcurrentOperationCount = maxCount;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = self.maxConcurrentOperationCount;
        self.removeEarliest = removeEarliest;
    }
    return self;
}

- (void)dealloc {
    [self cancelAllOperations];
}

#pragma mark - Interface

- (void)startOperation:(BDPNetworkOperation *)operation {
    if (operation == nil) {
        return;
    }
    
    @synchronized(_operationQueue) {
        if (self.removeEarliest && self.maxConcurrentOperationCount > 0 && [_operationQueue operationCount] >= self.maxConcurrentOperationCount) {
            [[[_operationQueue operations] firstObject] cancel];
        }
        [_operationQueue addOperation:operation];
    }
}

- (void)cancelAllOperations {
    @synchronized(_operationQueue) {
        [_operationQueue cancelAllOperations];
    }
}

@end
