//
//  IESDelegateFileDownloadTask.m
//  Pods
//
//  Created by 李彦松 on 2018/10/18.
//

#import "IESDelegateFileDownloadTask.h"
#import "IESEffectPlatformRequestManager.h"
@interface IESDelegateFileDownloadTask (){
    BOOL executing;
    BOOL finished;
}

@property (nonatomic,   copy) NSArray<NSString *> *urls;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, copy) NSDictionary *extraInfoDict;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation IESDelegateFileDownloadTask

- (instancetype)initWithURL:(NSArray<NSString *> *)urls filePath:(NSString *)filePath;
{
    NSParameterAssert(filePath);
    NSParameterAssert(urls.count > 0);
    
    self = [super init];
    if (self) {
        _filePath = filePath;
        _urls = [urls copy];
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (self.progress) {
        self.progress = nil;
    }
    dispatch_semaphore_signal(self.semaphore);
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        if (!self) {
            return;
        }
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        if (object == self.progress && [keyPath isEqualToString:@"completedUnitCount"]) {
            if (self.progress.completedUnitCount >= self.progress.totalUnitCount) {
                if (self.progressBlock) {
                    self.progressBlock(1);
                }
                self.progress = nil;
            } else {
                if (self.progressBlock) {
                    CGFloat percent = 0;
                    if (self.progress.totalUnitCount) {
                        percent = self.progress.completedUnitCount / (CGFloat)self.progress.totalUnitCount;
                    }
                    self.progressBlock(percent);
                }
            }
        }
        dispatch_semaphore_signal(self.semaphore);
    });
}

#pragma mark - Helpers

- (void)downloadRequestAtIndex:(NSUInteger)index
{
    if (index >= self.urls.count) {
        [self willChangeValueForKey:@"isExecuting"];
        executing = NO;
        [self didChangeValueForKey:@"isExecuting"];
        
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self requestDelegateWithIndex:index];
}

- (void)requestDelegateWithIndex:(NSUInteger)index{
    NSProgress *progress = nil;
    @weakify(self);
    void (^downloadCompletion)(NSError * _Nullable error, NSURL * _Nullable fileURL, NSDictionary * _Nullable extraInfoDict) = ^(NSError * _Nullable error, NSURL * _Nullable fileURL, NSDictionary * _Nullable extraInfoDict) {
        @strongify(self);
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        self.progress = nil;
        dispatch_semaphore_signal(self.semaphore);
        self.extraInfoDict = extraInfoDict;
        if (error) {
            self.error = error;
            [self downloadRequestAtIndex:++self.index];
            return;
        }
        NSError *fileError = nil;

        if (![fileURL isEqual:[NSURL fileURLWithPath:self.filePath]]) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:nil];
            }
            
            [[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:[NSURL fileURLWithPath:self.filePath] error:&fileError];
        }

        if (fileError) {
            self.error = fileError;
            [self downloadRequestAtIndex:++self.index];
        } else {
            self.error = nil;
            [self finishExecuting];
        }
    };
    IESEffectPreFetchProcessIfNeed(self.completionBlock, downloadCompletion)
    [self.requestDelegate downloadFileWithURLString:self.urls[index]
                                       downloadPath:[NSURL fileURLWithPath:self.filePath]
                                   downloadProgress:&progress
                                         completion:downloadCompletion];
    if (progress) {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        self.progress = progress;
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (void)finishExecuting {
    [self willChangeValueForKey:@"isExecuting"];
    executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    [self willChangeValueForKey:@"isFinished"];
    finished = YES;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - Override

- (void)start
{
    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{
    [self downloadRequestAtIndex:0];
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isExecuting
{
    return executing;
}

- (BOOL)isFinished
{
    return finished;
}

- (void)setProgress:(NSProgress *)progress
{
    if ([progress isEqual:_progress]) {
        return;
    }
    [_progress removeObserver:self forKeyPath:@"completedUnitCount" context:NULL];
    _progress = progress;
    [_progress addObserver:self forKeyPath:@"completedUnitCount" options:NSKeyValueObservingOptionNew context:NULL];
}

@end
