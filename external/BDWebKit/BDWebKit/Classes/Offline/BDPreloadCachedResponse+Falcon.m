//
//  BDPreloadCachedResponse+Falcon.m
//  BDWebKit
//
//  Created by wealong on 2019/12/5.
//

#import "BDPreloadCachedResponse+Falcon.h"
#import "NSObject+BDWRuntime.h"

@implementation BDPreloadCachedResponse(Falcon)

- (void)setFalconData:(NSData *)falconData {
    self.data = falconData;
}

- (NSData *)falconData {
    return self.data;
}

- (IESFalconStatModel *)statModel {
    return [self bdw_getAttachedObjectForKey:@"BDPreloadCachedResponse_StatModel"];
}

- (void)setStatModel:(IESFalconStatModel *)statModel {
    [self bdw_attachObject:statModel forKey:@"BDPreloadCachedResponse_StatModel"];
}

@end
