//
//  NSObject+BDTuring.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "NSObject+BDTuring.h"
#import "NSData+BDTuring.h"

@implementation NSObject (BDTuring)

- (NSData *)turing_JSONRepresentationData {
    id safeObject = [self turing_safeJsonObject];
    
    if (safeObject == nil) {
        return nil;
    }
    
    if (![NSJSONSerialization isValidJSONObject:safeObject]) {
        return nil;
    }

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:safeObject
                                                   options:0
                                                     error:&error];
    if (error) {
        return nil;
    }
    
    return data;
}

- (NSString *)turing_JSONRepresentation {
    NSData *data = [self turing_JSONRepresentationData];
    if (data == nil) {
        return nil;
    }

    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)turing_JSONRepresentationForJS {
    NSString *string = [self turing_JSONRepresentation];
    string = [string stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    string = [string stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];

    return string;
}

- (id)turing_safeJsonObject {
    return [self description];
}

@end
