//
//  TTHttpRequest.m
//  Pods
//
//  Created by gaohaidong on 9/23/16.
//
//

#import "TTHttpRequest.h"

@interface TTHttpRequest()
@property (nonnull, readwrite, strong) NSMutableDictionary<NSString *, NSNumber *> *serializerTimeInfo;
@property (nullable, readwrite, strong) NSMutableDictionary<NSString *, NSNumber *> *filterObjectsTimeInfo;
@property (nullable, readwrite, copy) NSDictionary *webviewInfo;
@property (atomic, readwrite, assign) BOOL isSerializedOnMainThread;
@end

@implementation TTHttpRequest

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.followRedirect = YES;
        self.filterObjectsTimeInfo = [NSMutableDictionary dictionary];
        self.serializerTimeInfo = [NSMutableDictionary dictionary];
        self.shouldReportLog = YES;
    }
    return self;
}

@end
