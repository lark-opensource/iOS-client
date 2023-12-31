//
//  VEAIMomentReframeInfo+WCTColumnCoding.mm
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import <TTVideoEditor/VEAIMomentReframeInfo.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <Foundation/Foundation.h>
#import <BDWCDB/WCDB/WCDB.h>

@interface VEAIMomentReframeInfo (WCTColumnCoding) <WCTColumnCoding>
@end

@implementation VEAIMomentReframeInfo (WCTColumnCoding)

+ (instancetype)unarchiveWithWCTValue:(NSData *)value
{
    if (value) {
        @try {
            VEAIMomentReframeInfo *info =  [NSKeyedUnarchiver unarchiveObjectWithData:value];
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

@interface VEAIMomentReframeInfo (NSCoding) <NSCoding>

@end

@implementation VEAIMomentReframeInfo (NSCoding)

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:self.score forKey:@"score"];
    [coder encodeFloat:self.frame.centerX forKey:@"frame.centerX"];
    [coder encodeFloat:self.frame.centerY forKey:@"frame.centerY"];
    [coder encodeFloat:self.frame.width forKey:@"frame.width"];
    [coder encodeFloat:self.frame.height forKey:@"frame.height"];
    [coder encodeFloat:self.frame.rotateAngle forKey:@"frame.rotateAngle"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self) {
        self.score = [coder decodeFloatForKey:@"score"];
        
        VEAIMomentReframeFrame frame;
        frame.centerX = [coder decodeFloatForKey:@"frame.centerX"];
        frame.centerY = [coder decodeFloatForKey:@"frame.centerY"];
        frame.width = [coder decodeFloatForKey:@"frame.width"];
        frame.height = [coder decodeFloatForKey:@"frame.height"];
        frame.rotateAngle = [coder decodeFloatForKey:@"frame.rotateAngle"];
        self.frame = frame;
    }
    
    return self;
}

- (NSString *)description
{
    NSDictionary *jsonDict =
    @{
        @"score": @(self.score),
        @"frame.centerX": @(self.frame.centerX),
        @"frame.centerY": @(self.frame.centerY),
        @"frame.width": @(self.frame.width),
        @"frame.height": @(self.frame.height),
        @"frame.rotateAngle": @(self.frame.rotateAngle),
    };
    return [jsonDict acc_dictionaryToJson];
}

@end
