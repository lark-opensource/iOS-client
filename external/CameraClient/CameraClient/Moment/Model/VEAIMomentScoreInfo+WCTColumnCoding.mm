//
//  VEAIMomentScoreInfo+WCTColumnCoding.mm
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <TTVideoEditor/VEAIMomentScoreInfo.h>
#import <BDWCDB/WCDB/WCDB.h>
#import "VEAIMomentScoreInfo+WCTColumnCoding.h"

@interface VEAIMomentScoreInfo (WCTColumnCoding) <WCTColumnCoding>
@end

@implementation VEAIMomentScoreInfo (WCTColumnCoding)

+ (instancetype)unarchiveWithWCTValue:(NSData *)value
{
    if (value) {
        @try {
            VEAIMomentScoreInfo *info =  [NSKeyedUnarchiver unarchiveObjectWithData:value];
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

@implementation VEAIMomentScoreInfo (NSCoding)

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:self.score forKey:@"score"];
    [coder encodeFloat:self.faceScore forKey:@"faceScore"];
    [coder encodeFloat:self.qualityScore forKey:@"qualityScore"];
    [coder encodeFloat:self.sharpnessScore forKey:@"sharpnessScore"];
    [coder encodeDouble:self.timeStamp forKey:@"timeStamp"];
    [coder encodeFloat:self.meaninglessScore forKey:@"meaninglessScore"];
    [coder encodeFloat:self.portraitScore forKey:@"portraitScore"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self) {
        self.score = [coder decodeFloatForKey:@"score"];
        self.faceScore = [coder decodeFloatForKey:@"faceScore"];
        self.qualityScore = [coder decodeFloatForKey:@"qualityScore"];
        self.sharpnessScore = [coder decodeFloatForKey:@"sharpnessScore"];
        self.timeStamp = [coder decodeDoubleForKey:@"timeStamp"];
        self.meaninglessScore = [coder decodeFloatForKey:@"meaninglessScore"];
        self.portraitScore = [coder decodeFloatForKey:@"portraitScore"];
    }
    
    return self;
}

- (NSString *)description
{
    NSDictionary *jsonDict =
    @{
        @"score": @(self.score),
        @"faceScore": @(self.faceScore),
        @"qualityScore": @(self.qualityScore),
        @"sharpnessScore": @(self.sharpnessScore),
        @"timeStamp": @(self.timeStamp),
        @"meaninglessScore": @(self.meaninglessScore),
        @"portraitScore": @(self.portraitScore),
    };
    return [jsonDict acc_dictionaryToJson];
}

- (NSDictionary *)acc_scoreInfoDict {
    NSDictionary *scoreInfo =
    @{
        @"timestamp": @(self.timeStamp),
        @"score": @(self.score),
        @"face_score": @(self.faceScore),
        @"quality_score": @(self.qualityScore),
        @"sharpness_score": @(self.sharpnessScore)
    };
    return scoreInfo;
}

@end
