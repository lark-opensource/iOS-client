//
//  NSError+TTVideoEngine.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/3/17.
//

#import "NSError+TTVideoEngine.h"

@implementation NSError (TTVideoEngine)

- (NSMutableDictionary *)ttvideoengine_getEventBasicInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:self.domain forKey:@"domain"];
    [dict setValue:@(self.code) forKey:@"code"];
    [dict setValue:self.description?:@"" forKey:@"description"];
    return dict;
}

@end
