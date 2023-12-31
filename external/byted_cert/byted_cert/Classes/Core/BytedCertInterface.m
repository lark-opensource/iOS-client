//
//  BytedCertDelegate.m
//  AFgzipRequestSerializer
//
//  Created by 潘冬冬 on 2019/8/27.
//

#import "BytedCertInterface.h"

@protocol TTBridgeAuthorization;


@interface BytedCertInterface ()

@property (nonatomic, weak) id<TTBridgeAuthorization> manager;
@property (nonatomic, strong) NSMutableArray *progressArray;

@end


@implementation BytedCertInterface

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BytedCertInterface *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BytedCertInterface alloc] init];
    });

    return instance;
}

- (void)setBytedCertCameraImage:(UIImage *)image {
    self.bytedCertCameraCallback(image);
}

- (void)setBridgeAuthorization:(id<TTBridgeAuthorization>)manager {
    self.manager = manager;
}

/// 添加多个回调
- (void)addProgressDelegate:(id<BytedCertProgressDelegate>)bytedCertProgressDelegate {
    if (bytedCertProgressDelegate && [bytedCertProgressDelegate conformsToProtocol:@protocol(BytedCertProgressDelegate)] && ![self.progressArray containsObject:bytedCertProgressDelegate]) {
        [self.progressArray addObject:bytedCertProgressDelegate];
    }
}

/// 移除当前不使用回调
- (void)removeProgressDelegate:(id<BytedCertProgressDelegate>)bytedCertProgressDelegate {
    if (bytedCertProgressDelegate && [bytedCertProgressDelegate conformsToProtocol:@protocol(BytedCertProgressDelegate)]) {
        if ([self.progressArray indexOfObject:bytedCertProgressDelegate] != NSNotFound) {
            [self.progressArray removeObject:bytedCertProgressDelegate];
        }
    }
}

/// 获取当前所有代理对象，触发回调
- (NSArray *)progressDelegateArray {
    if (self.progressArray.count > 0) {
        return [self.progressArray copy];
    }

    return nil;
}

- (NSMutableArray *)progressArray {
    if (!_progressArray) {
        _progressArray = [[NSMutableArray alloc] init];
    }
    return _progressArray;
}

- (void)updateAuthParams:(NSDictionary *)params {
    // Do nothing
}

@end
