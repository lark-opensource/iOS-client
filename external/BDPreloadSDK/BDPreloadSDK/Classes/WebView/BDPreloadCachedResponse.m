//
//  BDPreloadCachedResponse.m
//  BDPreloadSDK
//
//  Created by Nami on 2019/2/2.
//

#import "BDPreloadCachedResponse.h"

@implementation BDPreloadCachedResponse

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.statusCode = [aDecoder decodeIntegerForKey:@"statusCode"];
        self.allHeaderFields = [aDecoder decodeObjectForKey:@"allHeaderFields"];
        self.data = [aDecoder decodeObjectForKey:@"data"];
        self.saveTime = [aDecoder decodeDoubleForKey:@"saveTime"];
        self.cacheDuration = [aDecoder decodeDoubleForKey:@"cacheDuration"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_statusCode forKey:@"statusCode"];
    [aCoder encodeObject:_allHeaderFields forKey:@"allHeaderFields"];
    [aCoder encodeObject:_data forKey:@"data"];
    [aCoder encodeDouble:_saveTime forKey:@"saveTime"];
    [aCoder encodeDouble:_cacheDuration forKey:@"cacheDuration"];
}

@end
