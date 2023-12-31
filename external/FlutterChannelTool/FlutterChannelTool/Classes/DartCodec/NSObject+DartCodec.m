//
//  NSObject+DartCodec.m
//  FlutterChannelTool
//
//  Created by zhangtianfu on 2019/1/22.
//

#import "NSObject+DartCodec.h"

@implementation NSObject (DartCodec)

- (NSString *)dart_string {
    return ([self isKindOfClass:[NSString class]] ? (NSString*)self : nil);
}

- (NSDictionary *)dart_dictionary {
    return ([self isKindOfClass:[NSDictionary class]] ? (NSDictionary*)self : nil);
}

- (NSArray *)dart_array {
    return ([self isKindOfClass:[NSArray class]] ? (NSArray*)self : nil);
}

- (NSNumber *)dart_number {
    return ([self isKindOfClass:[NSNumber class]] ? (NSNumber*)self : nil);
}

- (id)dart_FlutterStandardTypedData {
    return ([NSStringFromClass([self class]) isEqualToString:@"FlutterStandardTypedData"] ? self : nil) ;
}

@end

