//
//  NSData+BDTuring.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "NSData+BDTuring.h"

@implementation NSData (BDTuring)

- (NSMutableDictionary *)turing_mutableDictionaryFromJSONData {
    id object = [self turing_objectFromJSONData];
    if (![object isKindOfClass:[NSMutableDictionary class]]) {
        return nil;
    }
    
    return object;
}

- (id)turing_objectFromJSONData {
    if (self.length < 1) {
        return nil;
    }

    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:self
                                                options:NSJSONReadingMutableContainers
                                                  error:&error];
    if (error) {
        return nil;
    }

    return object;
}

- (BOOL)turing_isGzipCompressed {
    if (self.length < 3) {
        return NO;
    }

    NSData *subdata = [self subdataWithRange:NSMakeRange(0, 3)];
    const Byte *bytes = (const Byte *)subdata.bytes;
    
    return bytes[0] == 0x1f && bytes[1] == 0x8b && bytes[2] == 0x08;
}


@end
