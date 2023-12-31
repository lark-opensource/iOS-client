// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestWorkflow.h"
#import "IESForestResponse.h"
#import "IESForestRequest.h"
#import "IESForestKit+private.h"
#import "IESForestError.h"

#import "IESForestMemoryFetcher.h"
#import "IESForestGeckoFetcher.h"
#import "IESForestBuiltinFetcher.h"
#import "IESForestCDNFetcher.h"

#import <IESGeckoKit/IESGurdLogProxy.h>
#import <ByteDanceKit/BTDMacros.h>

#pragma mark - IESForestWorkflowDebugInfo
@interface IESForestWorkflowDebugInfo : NSObject
@property (nonatomic, copy) NSString* step;
@property (nonatomic, copy) NSString* message;
@property (nonatomic, assign) NSInteger code;
@end

@implementation IESForestWorkflowDebugInfo

- (instancetype)initWithStep:(NSString *)step code:(NSInteger)code message:(NSString *)message
{
    if (self = [super init]) {
        _step = step;
        _message = message;
        _code = code;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", self.step, self.message];
}

@end

#pragma mark - IESForestWorkflowState
typedef NS_ENUM(NSInteger, IESForestWorkflowState) {
    IESForestWorkflowStateRunnable,
    IESForestWorkflowStateCancelled,
    IESForestWorkflowStateCompleted,
    IESForestWorkflowStateRunning,
};

@interface IESForestWorkflow ()

@property (nonatomic, strong) id<IESForestFetcherProtocol> currentFetcher;
@property (nonatomic, assign) NSUInteger currentFetcherIndex;
@property (nonatomic, strong) NSArray<NSNumber *> *fetchers;

@property (nonatomic, copy) IESForestCompletionHandler completion;

@property (nonatomic, assign) IESForestWorkflowState state;
@property (nonatomic, strong) NSMutableArray *debugInfos;

@end

@implementation IESForestWorkflow

- (instancetype)initWithFetchers:(NSArray<NSNumber *> *)fetchers
                         request:(IESForestRequest *)request
{
    self = [super init];
    if (self) {
        self.fetchers = fetchers;
        if (![fetchers containsObject:@(IESForestFetcherTypeGecko)]) {
            request.geckoErrorCode = IESForestErrorGeckoDisabled;
            request.geckoError = @"Gecko disabled!";
        }
        self.request = request;
        self.currentFetcherIndex = 0;
        self.debugInfos = [NSMutableArray new];
        self.state = IESForestWorkflowStateRunnable;
    }
    return self;
}

- (BOOL)cancelFetch {
    if (self.state == IESForestWorkflowStateCancelled || self.state == IESForestWorkflowStateCompleted) {
        return NO;
    }

    self.state = IESForestWorkflowStateCancelled;
    [self.currentFetcher cancelFetch];
    NSError *error = [IESForestError errorWithCode:IESForestErrorWorkflowCancel message:@"Request was cancelled"];

    IESGurdLogInfo(@"Forest - Workflow: request [%@] was cancelled", self.request.url);
    [self appendDebugInfoWithStep:@"Workflow" code:error.code message:error.localizedDescription];
    if (self.completion) {
        self.completion(nil, error);
    }
    return YES;
}

- (void)fetchResourceWithCompletion:(IESForestCompletionHandler)completionHandler
{
    if (self.state != IESForestWorkflowStateRunnable) {
        return;
    }
    self.state = IESForestWorkflowStateRunning;
    if (self.request.isSync || !self.request.runWorkflowInGlobalQueue) {
        [self _fetchResourceWithCompletion:completionHandler];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _fetchResourceWithCompletion:completionHandler];
        });
    }
}

- (void)_fetchResourceWithCompletion:(IESForestCompletionHandler)completion
{
    NSAssert(completion != nil, @"Completion in workflow should not be nil");
    // store completion, so it can be used when cancel fetch
    if (!self.completion) {
        self.completion = completion;
    }

    if (self.fetchers.count == 0) {
        self.state = IESForestWorkflowStateCompleted;
        NSError *error = [IESForestError errorWithCode:IESForestErrorWorkflowNoFetchers message:@"No fetchers available"];
        [self appendDebugInfoWithStep:@"Workflow" code:error.code message:error.localizedDescription];
        IESForestResponse *forestResponse = [[IESForestResponse alloc] initWithRequest:self.request];
        completion(forestResponse, error);
        return;
    }

    @weakify(self);
    IESForestCompletionHandler wrapCompletion = ^(id<IESForestResponseProtocol> __nullable response, NSError *__nullable error) {
        @strongify(self);
        if (self.state != IESForestWorkflowStateRunning) {
            return;
        }
        if (!error) {
            self.state = IESForestWorkflowStateCompleted;
            NSString *message = @"Success";
            if ([self.currentFetcher respondsToSelector:@selector(debugMessage)]) {
                message = self.currentFetcher.debugMessage;
            }
            [self appendDebugInfoWithStep:self.currentFetcher.name code: 0 message:message];
            IESForestResponse *forestResponse = [IESForestResponse responseWithResponse:response];
            forestResponse.debugInfo = [self debugInfo];
            completion(forestResponse, nil);
        } else {
            [self appendDebugInfoWithStep:self.currentFetcher.name code:error.code message:error.localizedDescription];
            if (self.currentFetcherIndex == self.fetchers.count) {
                self.state = IESForestWorkflowStateCompleted;
                IESForestResponse *forestResponse = [[IESForestResponse alloc] initWithRequest:self.request];
                completion(forestResponse, [IESForestError errorWithCode:[self finalErrorCode] message:[self debugInfo]]);
            } else {
                [self _fetchResourceWithCompletion:completion];
            }
        }
    };

    NSNumber *currentFetcherType = self.fetchers[self.currentFetcherIndex++];
    self.currentFetcher = [self createFetcherWithType:currentFetcherType];
    if (self.currentFetcher) {
        [self.currentFetcher fetchResourceWithRequest:self.request completion:wrapCompletion];
    }
}

- (nullable NSString *)debugInfo
{
    NSString *message = [[self debugInfos] componentsJoinedByString:@","];
    return [NSString stringWithFormat:@"{%@}", message];
}

- (NSString *)fetcherNames
{
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:[self.fetchers count]];
    [self.fetchers enumerateObjectsUsingBlock:^(NSNumber * _Nonnull type, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [NSString stringWithFormat:@"%d", [type intValue]];
        Class<IESForestFetcherProtocol> clz = [[IESForestKit fetcherDictionary] valueForKey:key];
        if ([clz respondsToSelector:@selector(fetcherName)]) {
            [names addObject:[clz performSelector:@selector(fetcherName)]];
        } else {
            [names addObject:NSStringFromClass(clz)];
        }
    }];
    return [NSString stringWithFormat:@"[%@]", [names componentsJoinedByString:@","]];
}

- (NSInteger)finalErrorCode
{
    __block NSInteger code = 0;
    [self.debugInfos enumerateObjectsUsingBlock:^(IESForestWorkflowDebugInfo *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        code += obj.code;
    }];
    return code;
}

- (void)appendDebugInfoWithStep:(NSString *)step code:(NSInteger)code message:(NSString *)message
{
    [self.debugInfos addObject:[[IESForestWorkflowDebugInfo alloc] initWithStep:step code:code message:message]];
}

#pragma mark - private

- (nullable id<IESForestFetcherProtocol>)createFetcherWithType:(NSNumber *)type
{
    NSString *key = [NSString stringWithFormat:@"%d", [type intValue]];
    Class<IESForestFetcherProtocol> clz = [[IESForestKit fetcherDictionary] valueForKey:key];
    if ([clz conformsToProtocol:@protocol(IESForestFetcherProtocol)]) {
        id<IESForestFetcherProtocol> fetcher = [[clz class] new];
        if ([fetcher isKindOfClass:[IESForestBaseFetcher class]]) {
            ((IESForestBaseFetcher *)fetcher).request = self.request;
            ((IESForestBaseFetcher *)fetcher).forestKit = self.forestKit;
        }
        return fetcher;
    }
    return nil;
}

@end
