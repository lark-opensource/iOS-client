//
//  VEAIMomentFaceFeature+WCTColumnCoding.mm
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import <TTVideoEditor/VEAIMomentFaceFeature.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <Foundation/Foundation.h>
#import <BDWCDB/WCDB/WCDB.h>
#import "VEAIMomentFaceFeature+WCTColumnCoding.h"

@interface VEAIMomentFaceFeature (WCTColumnCoding) <WCTColumnCoding>
@end

@implementation VEAIMomentFaceFeature (WCTColumnCoding)

+ (instancetype)unarchiveWithWCTValue:(NSData *)value
{
    if (value) {
        @try {
            VEAIMomentFaceFeature *info =  [NSKeyedUnarchiver unarchiveObjectWithData:value];
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

@implementation VEAIMomentFaceFeature (NSCoding)

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt64:self.faceId forKey:@"faceId"];
    [coder encodeFloat:self.yaw forKey:@"yaw"];
    [coder encodeFloat:self.pitch forKey:@"pitch"];
    [coder encodeFloat:self.roll forKey:@"roll"];
    [coder encodeDouble:self.realFaceProb forKey:@"realFaceProb"];
    [coder encodeFloat:self.quailty forKey:@"quailty"];
    [coder encodeFloat:self.boyProb forKey:@"boyProb"];
    [coder encodeFloat:self.age forKey:@"age"];
    [coder encodeFloat:self.happyScore forKey:@"happyScore"];
    
    [coder encodeFloat:self.rect.left forKey:@"rect.left"];
    [coder encodeFloat:self.rect.top forKey:@"rect.top"];
    [coder encodeFloat:self.rect.right forKey:@"rect.right"];
    [coder encodeFloat:self.rect.bottom forKey:@"rect.bottom"];
    
    [coder encodeInt:self.box.lu_x forKey:@"box.lu_x"];
    [coder encodeInt:self.box.lu_y forKey:@"box.lu_y"];
    [coder encodeInt:self.box.ru_x forKey:@"box.ru_x"];
    [coder encodeInt:self.box.ru_y forKey:@"box.ru_y"];
    [coder encodeInt:self.box.ld_x forKey:@"box.ld_x"];
    [coder encodeInt:self.box.ld_y forKey:@"box.ld_y"];
    [coder encodeInt:self.box.rd_x forKey:@"box.rd_x"];
    [coder encodeInt:self.box.rd_y forKey:@"box.rd_y"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    if (self) {
        self.faceId = [coder decodeInt64ForKey:@"faceId"];
        self.yaw = [coder decodeFloatForKey:@"yaw"];
        self.pitch = [coder decodeFloatForKey:@"pitch"];
        self.roll = [coder decodeFloatForKey:@"roll"];
        self.realFaceProb = [coder decodeDoubleForKey:@"realFaceProb"];
        self.quailty = [coder decodeFloatForKey:@"quailty"];
        self.boyProb = [coder decodeFloatForKey:@"boyProb"];
        self.age = [coder decodeFloatForKey:@"age"];
        self.happyScore = [coder decodeFloatForKey:@"happyScore"];
        
        VEEffectRectF rect;
        rect.left = [coder decodeFloatForKey:@"rect.left"];
        rect.top = [coder decodeFloatForKey:@"rect.top"];
        rect.right = [coder decodeFloatForKey:@"rect.right"];
        rect.bottom = [coder decodeFloatForKey:@"rect.bottom"];
        self.rect = rect;
        
        VEEffectBoxI box;
        box.lu_x = [coder decodeIntForKey:@"box.lu_x"];
        box.lu_y = [coder decodeIntForKey:@"box.lu_y"];
        box.ru_x = [coder decodeIntForKey:@"box.ru_x"];
        box.ru_y = [coder decodeIntForKey:@"box.ru_y"];
        box.ld_x = [coder decodeIntForKey:@"box.ld_x"];
        box.ld_y = [coder decodeIntForKey:@"box.ld_y"];
        box.rd_x = [coder decodeIntForKey:@"box.rd_x"];
        box.rd_y = [coder decodeIntForKey:@"box.rd_y"];
        self.box = box;
    }
    
    return self;
}

- (NSString *)description
{
    NSDictionary *jsonDict =
    @{
        @"faceId": @(self.faceId),
        @"yaw": @(self.yaw),
        @"pitch": @(self.pitch),
        @"roll": @(self.roll),
        @"realFaceProb": @(self.realFaceProb),
        @"quailty": @(self.quailty),
        @"boyProb": @(self.boyProb),
        @"age": @(self.age),
        @"happyScore": @(self.happyScore),
        @"rect.left": @(self.rect.left),
        @"rect.top": @(self.rect.top),
        @"rect.right": @(self.rect.right),
        @"rect.bottom": @(self.rect.bottom),
        @"box.lu_x": @(self.box.lu_x),
        @"box.lu_y": @(self.box.lu_y),
        @"box.ru_x": @(self.box.ru_x),
        @"box.ru_y": @(self.box.ru_y),
        @"box.ld_x": @(self.box.ld_x),
        @"box.ld_y": @(self.box.ld_y),
        @"box.rd_x": @(self.box.rd_x),
        @"box.rd_y": @(self.box.rd_y),
    };
    return [jsonDict acc_dictionaryToJson];
}

- (NSDictionary *)acc_faceInfoDict {
    NSDictionary *faceInfo =
    @{
        @"boy_prob": @(self.boyProb),
        @"age": @(self.age),
        @"real_prob": @(self.realFaceProb),
        @"face_id": @(self.faceId),
        @"yaw": @(self.yaw),
        @"pitch": @(self.pitch),
        @"roll": @(self.roll),
        @"quality": @(self.quailty),
        @"happy_score": @(self.happyScore),
        @"rect": [self acc_bboxInfo],
        @"norm_rect": [self acc_rect],
    };
    return faceInfo;
}

- (NSDictionary *)acc_bboxInfo {
    NSDictionary *bboxInfo =
    @{
        @"lu_x": @(self.box.lu_x),
        @"lu_y": @(self.box.lu_y),
        @"ru_x": @(self.box.ru_x),
        @"ru_y": @(self.box.ru_y),
        @"ld_x": @(self.box.ld_x),
        @"ld_y": @(self.box.ld_y),
        @"rd_x": @(self.box.rd_x),
        @"rd_y": @(self.box.rd_y),
    };
    return bboxInfo;
}

- (NSDictionary *)acc_rect {
    NSDictionary *rectInfo =
    @{
        @"top": @(self.rect.top),
        @"bottom": @(self.rect.bottom),
        @"left": @(self.rect.left),
        @"right": @(self.rect.right),
    };
    return rectInfo;
}

@end
