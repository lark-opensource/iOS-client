//
//  TMATextBackedString.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMATextBackedString.h"

NSString *const TMATextBackedStringAttributeName = @"TMATextBackedString";

@implementation TMATextBackedString

+ (instancetype)stringWithString:(NSString *)string {
    TMATextBackedString *one = [[self alloc] init];
    one.string = string;
    return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.string forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _string = [aDecoder decodeObjectForKey:@"string"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) one = [[self.class alloc] init];
    one.string = self.string;
    return one;
}

@end
