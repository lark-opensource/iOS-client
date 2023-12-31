// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRequestOperationManager.h"
#import "IESForestRequestOperation.h"
#import "IESForestRequest.h"
#import "IESForestWorkflow.h"

@interface IESForestRequestOperationManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString*, IESForestRequestOperation*> *operationsDict;
@property (nonatomic, strong) NSLock *operationDictLock;
@property (nonatomic, strong) NSMutableArray<IESForestRequestOperation*> *operationsArray;
@property (nonatomic, strong) NSLock *operationArrayLock;

@end

@implementation IESForestRequestOperationManager

- (instancetype)init
{
    if (self = [super init]) {
        _operationsDict = [NSMutableDictionary dictionary];
        _operationsArray = [NSMutableArray array];
        _operationDictLock = [[NSLock alloc] init];
        _operationArrayLock = [[NSLock alloc] init];
    }
    return self;
}

- (IESForestRequestOperation *)operationWithRequest:(IESForestRequest *)request
{
    if (!(request.enableRequestReuse || request.isPreload)) {
        IESForestRequestOperation *operation = [[IESForestRequestOperation alloc] initWithRequest:request forestKit:self.forestKit];
        [self.operationArrayLock lock];
        [self.operationsArray addObject:operation];
        [self.operationArrayLock unlock];
        return operation;
    }

    NSString *key = [request identity];
    [self.operationDictLock lock];
    IESForestRequestOperation *operation = [self.operationsDict objectForKey:key];
    request.isRequestReused = (operation != nil);
    if (!operation) {
        operation = [[IESForestRequestOperation alloc] initWithRequest:request forestKit:self.forestKit];
        [self.operationsDict setObject:operation forKey:key];
    }
    [self.operationDictLock unlock];
    return operation;
}

- (void)removeOperation:(IESForestRequestOperation *)operation
{
    IESForestRequest *request = operation.workflow.request;
    if (!(request.enableRequestReuse || request.isPreload)) {
        [self.operationArrayLock lock];
        [self.operationsArray removeObject:operation];
        [self.operationArrayLock unlock];
    } else {
        NSString *key = [request identity];
        if (!key) return;
        [self.operationDictLock lock];
        [self.operationsDict removeObjectForKey:key];
        [self.operationDictLock unlock];
    }
}

@end
