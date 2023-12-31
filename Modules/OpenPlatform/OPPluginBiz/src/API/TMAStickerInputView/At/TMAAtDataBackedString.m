//
//  TMAAtDataBackedString.m
//  OPPluginBiz
//
//  Created by houjihu on 2018/9/5.
//

#import "TMAAtDataBackedString.h"

NSString *const TMAAtDataBackedStringAttributeName = @"TMAAtDataBackedString";

@implementation TMAAtDataBackedString

+ (nullable instancetype)stringWithString:(nullable NSString *)string larkID:(nullable NSString *)larkID openID:(nullable NSString *)openID userName:(NSString *)userName {
    TMAAtDataBackedString *one = [[self alloc] init];
    one.string = string;
    one.larkID = larkID;
    one.openID = openID;
    one.userName = userName;
    return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.string forKey:NSStringFromSelector(@selector(string))];
    [aCoder encodeObject:self.larkID forKey:NSStringFromSelector(@selector(larkID))];
    [aCoder encodeObject:self.openID forKey:NSStringFromSelector(@selector(openID))];
    [aCoder encodeObject:self.userName forKey:NSStringFromSelector(@selector(userName))];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _string = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(string))];
        _larkID = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(larkID))];
        _openID = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(openID))];
        _userName = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(userName))];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    typeof(self) one = [[self.class alloc] init];
    one.string = self.string;
    one.larkID = self.larkID;
    one.openID = self.openID;
    one.userName = self.userName;
    return one;
}

@end
