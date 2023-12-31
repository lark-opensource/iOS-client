//
//  NSString+BDTuring.m
//  BDTuring
//
//  Created by bob on 2020/3/3.
//

#import "NSString+BDTuring.h"
#import "NSData+BDTuring.h"

@implementation NSString (BDTuring)

- (id)turing_dictionaryFromBase64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self
                                                       options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (data == nil) {
        return nil;
    }
    
    id value = [data turing_objectFromJSONData];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    
    return nil;
}

- (NSDictionary *)turing_dictionaryFromJSONString {
    id value = [self turing_objectFromJSONString];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    
    return nil;
}

- (id)turing_objectFromJSONString {
    if (self.length < 1) {
        return nil;
    }

    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }

    return [data turing_objectFromJSONData];
}

- (id)turing_safeJsonObject {
    return [self copy];
}

@end
