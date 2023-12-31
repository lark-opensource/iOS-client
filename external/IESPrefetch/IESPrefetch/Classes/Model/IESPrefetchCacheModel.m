//
//  IESPrefetchCacheModel.m
//  IESPrefetch
//
//  Created by Hao Wang on 2019/8/21.
//

#import "IESPrefetchCacheModel.h"

@interface IESPrefetchCacheModel ()

@property(nonatomic, readwrite, assign) NSTimeInterval timeInterval;
@property(nonatomic, readwrite, assign) NSTimeInterval expires;
@property(nonatomic, readwrite, strong) id data;

@end

@implementation IESPrefetchCacheModel

+ (instancetype)modelWithData:(id)data
                 timeInterval:(NSTimeInterval)timeInterval
                      expires:(NSTimeInterval)expires {
    IESPrefetchCacheModel *model = [IESPrefetchCacheModel new];
    model.data = data;
    model.timeInterval = timeInterval;
    model.expires = expires;
    return model;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.timeInterval = [dictionary[@"__timeInterval"] doubleValue];
        self.expires = [dictionary[@"__expires"] doubleValue];
        NSString *json = dictionary[@"__data"];
        if ([json isKindOfClass:[NSString class]]) {
            NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
            if (jsonData) {
                self.data = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
            }
        }
    }
    return self;
}

- (NSDictionary *)jsonSerializationDictionary {
    if (![NSJSONSerialization isValidJSONObject:self.data]) {
        return nil;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    dict[@"__timeInterval"] = @(self.timeInterval);
    dict[@"__expires"] = @(self.expires);
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.data options:NSJSONWritingFragmentsAllowed error:&error];
    if (error) {
        return nil;
    }
    dict[@"__data"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [dict copy];
}

- (BOOL)hasExpired {
    int64_t now = [[NSDate date] timeIntervalSince1970];
    if (self.data && now >= self.timeInterval + self.expires) {
        return YES;
    }
    return NO;
}

@end
