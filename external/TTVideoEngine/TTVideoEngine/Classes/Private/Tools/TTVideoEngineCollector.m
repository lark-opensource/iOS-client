//
//  TTVideoEngineCollector.m
//  TTVideoEngine
//
//  Created by coeus on 2021/3/23.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineCollector.h"
NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineCollectorInner : NSObject

@property(nonatomic, assign) int64_t mPlayConsumedSize;

+ (id)sharedInstance;
- (void)updatePlayConsumedSize:(int64_t) size;
- (int64_t)getPlayConsumedSize;

@end

@implementation TTVideoEngineCollector

+ (void)updatePlayConsumedSize:(int64_t)size {
    [[TTVideoEngineCollectorInner sharedInstance] updatePlayConsumedSize:size];
}
+ (int64_t) getPlayConsumeSize {
    return [[TTVideoEngineCollectorInner sharedInstance] getPlayConsumedSize];
}

@end

@implementation TTVideoEngineCollectorInner

+ (id)sharedInstance {
    static TTVideoEngineCollectorInner* _sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sInstance = [[self alloc] init];
    });
    
    return _sInstance;
}

- (id) init {
    self = [super init];
    if(self) {
        self.mPlayConsumedSize = 0;
    }
    return self;
}

- (void)updatePlayConsumedSize:(int64_t) size {
    if (size <= 0) {
        return;
    }
    @synchronized (self) {
        self.mPlayConsumedSize += size;
    }
}
- (int64_t)getPlayConsumedSize {
    int64_t ret = self.mPlayConsumedSize;
    @synchronized (self) {
        self.mPlayConsumedSize = 0;
    }
    return ret;
}

@end


NS_ASSUME_NONNULL_END
