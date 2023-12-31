//
//  NSArray+BDNativeWebHelper.m
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/9/26.
//

#import "NSArray+BDNativeWebHelper.h"

@implementation NSArray (BDNativeHelper)

- (NSString *)bdNative_JSONRepresentation
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return dataStr;
}

@end
