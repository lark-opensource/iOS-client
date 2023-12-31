//
//  BDTuringParameter.m
//  BDTuring
//
//  Created by bob on 2020/9/6.
//

#import "BDTuringParameter.h"
#import "BDTuringVerifyModel.h"

@interface BDTuringParameter ()

@property (atomic, copy) NSDictionary *parameter;
@property (nonatomic, assign) long long timestamp;
@property (nonatomic, strong) NSMutableDictionary<NSString * ,Class<BDTuringVerifyModelCreator>> *creators;

@end

@implementation BDTuringParameter

+ (instancetype)sharedInstance {
    static BDTuringParameter *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.parameter = nil;
        self.timestamp = 0;
        self.creators = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)updateCurrentParameter:(NSDictionary *)parameter {
    if (parameter == nil) {
        return;
    }
    
    self.parameter = parameter;
    self.timestamp = CACurrentMediaTime();
}

- (NSDictionary *)currentParameter {
    long long now = CACurrentMediaTime();
    /// timeout 5 * 60s
    if (now - self.timestamp > 300) {
        self.parameter = nil;
    }
    
    return self.parameter;
}

- (void)addCreator:(Class<BDTuringVerifyModelCreator>)creator {
    [self.creators setValue:creator forKey:NSStringFromClass(creator)];
}

- (BDTuringVerifyModel *)modelWithParameter:(NSDictionary *)parameter {
    BDTuringVerifyModel *value = nil;
    for (NSString *key in self.creators) {
        Class<BDTuringVerifyModelCreator> creator = [self.creators objectForKey:key];
        if ([creator canHandleParameter:parameter]) {
            value = [creator modelWithParameter:parameter];
        }
        if (value != nil) {
            break;
        }
    }
    NSCAssert(value != nil, @"BDTuringVerifyModel parameter error");
    return value;
}

@end
