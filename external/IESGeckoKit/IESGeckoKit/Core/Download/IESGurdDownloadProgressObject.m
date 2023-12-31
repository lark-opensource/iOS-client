//
//  IESGurdDownloadProgressObject.m
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/4.
//

#import "IESGurdDownloadProgressObject+Private.h"

@implementation IESGurdDownloadProgressObject

+ (instancetype)object
{
    IESGurdDownloadProgressObject *object = [[self alloc] init];
    object.progressBlocks = [NSMutableArray array];
    return object;
}

- (void)addProgressBlock:(void (^)(NSProgress *progress))progressBlock
{
    if (!progressBlock) {
        return;
    }
    @synchronized (self) {
        [self.progressBlocks addObject:progressBlock];
    }
}

- (void)startObservingWithProgress:(NSProgress *)progress
{
    if (self.progress) {
        return;
    }
    self.progress = progress;
    [self.progress addObserver:self
                    forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                       options:NSKeyValueObservingOptionNew
                       context:nil];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))]) {
        NSProgress *progress = self.progress;
        for (void (^progressBlock)(NSProgress *progress) in self.progressBlocks) {
            progressBlock(progress);
        }
    }
}

- (void)dealloc
{
    @try {
        [self.progress removeObserver:self
                           forKeyPath:NSStringFromSelector(@selector(fractionCompleted))
                              context:nil];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}

@end
