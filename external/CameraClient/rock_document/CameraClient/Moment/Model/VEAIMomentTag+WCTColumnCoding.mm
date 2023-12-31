//
//  VEAIMomentTag+WCTColumnCoding.mm
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import <TTVideoEditor/VEAIMomentTag.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <Foundation/Foundation.h>
#import <BDWCDB/WCDB/WCDB.h>
#import "VEAIMomentTag+WCTColumnCoding.h"

@interface VEAIMomentTag (WCTColumnCoding) <WCTColumnCoding>
@end

@implementation VEAIMomentTag (WCTColumnCoding)

+ (instancetype)unarchiveWithWCTValue:(NSData *)value
{
    if (value) {
        @try {
            VEAIMomentTag *info =  [NSKeyedUnarchiver unarchiveObjectWithData:value];
            return info;
        }
        @catch (NSException *exception) {
            
        }
    }
    return nil;
}

- (NSData *)archivedWCTValue
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];;
}

+ (WCTColumnType)columnTypeForWCDB
{
    return WCTColumnTypeBinary;
}

@end

@implementation VEAIMomentTag (NSCoding)

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt64:self.identity forKey:@"identity"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeInteger:self.type forKey:@"type"];
    [coder encodeFloat:self.confidence forKey:@"confidence"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self) {
        self.identity = [coder decodeInt64ForKey:@"identity"];
        self.name = [coder decodeObjectForKey:@"name"];
        self.type = [coder decodeIntegerForKey:@"type"];
        self.confidence = [coder decodeFloatForKey:@"confidence"];
    }
    
    return self;
}

- (NSString *)description
{
    NSDictionary *jsonDict =
    @{
        @"identity": @(self.identity),
        @"name": self.name? : @"",
        @"type": @(self.type),
        @"confidence": @(self.confidence),
    };
    return [jsonDict acc_dictionaryToJson];
}

- (NSDictionary *)acc_tagInfoDict
{
    NSDictionary *tagInfo = @{
        @"id": @(self.identity),
        @"prob": @(self.confidence),
        @"name": self.name ?: @"",
        @"type": @(self.type),
    };
    return tagInfo;
}

@end
