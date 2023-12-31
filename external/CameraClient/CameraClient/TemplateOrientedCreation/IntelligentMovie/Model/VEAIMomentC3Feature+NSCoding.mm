//
//  VEAIMomentC3Feature+NSCoding.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/12/14.
//

#import "VEAIMomentC3Feature+NSCoding.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <BDWCDB/WCDB/WCDB.h>

@interface VEAIMomentC3Feature (WCTColumnCoding) <WCTColumnCoding>
@end

@implementation VEAIMomentC3Feature (WCTColumnCoding)

+ (instancetype)unarchiveWithWCTValue:(NSData *)value
{
    if (value) {
        @try {
            VEAIMomentC3Feature *info =  [NSKeyedUnarchiver unarchiveObjectWithData:value];
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

@implementation VEAIMomentC3Feature (NSCoding)

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeObject:@(self.featureLength) forKey:@"featureLength"];
    [coder encodeObject:self.featureData?:@[] forKey:@"featureData"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    self = [super init];
    
    if (self) {
        self.featureLength = [[coder decodeObjectForKey:@"featureLength"] longLongValue];
        self.featureData = [coder decodeObjectForKey:@"featureData"];
    }
    
    return self;
}

- (NSString *)description
{
    NSDictionary *jsonDict =
    @{
        @"featureData": self.featureData,
        @"featureLength": @(self.featureLength),
    };
    return [jsonDict acc_dictionaryToJson];
}

@end
