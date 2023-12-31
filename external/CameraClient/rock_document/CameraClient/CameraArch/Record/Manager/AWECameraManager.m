//
//  AWECameraManager.m
//  Aweme
//
//  Created by Liu Bing on 9/6/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWECameraManager.h"

@interface AWECameraManager ()

@property (nonatomic, strong) NSPointerArray *recorderArray;

@end

@implementation AWECameraManager

+ (instancetype)sharedManager
{
    static AWECameraManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init {
    if (self = [super init]) {
        _taskIdSet = [NSMutableSet set];
    }
    return self;
}

- (void)addRecorder:(UIViewController *)recorder {
    if (!recorder) return;
    @synchronized (self.recorderArray) {
        [self.recorderArray addPointer:(__bridge void *)recorder];
    };
}

- (NSArray<UIViewController *> *)allRecorders {
    NSArray *res;
    @synchronized (self.recorderArray) {
        @autoreleasepool { // -[NSPointerArray allObjects] is autoreleasing, put a pool here to make sure the existing recorder instances can be released timely.
            res = [self.recorderArray allObjects];
        }
    }
    return res;
}

#pragma mark - getter

- (NSPointerArray *)recorderArray {
    if (!_recorderArray) {
        _recorderArray = [NSPointerArray weakObjectsPointerArray];
    }
    return _recorderArray;
}

@end
