//
//  CJPayBaseResponse.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/24.
//

#import "CJPayBaseResponse.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBaseResponse

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    self = [super initWithDictionary:dict error:err];
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
    CFTimeInterval costTime = endTime - startTime;
    
    [[CJPayJsonParseTracker sharedInstance] recordParseProcessWithClassName:[self btd_className]
                                                                   costTime:costTime
                                                                   modelDic:dict];
    return self;
}

- (BOOL)isSuccess {
    return [self.code isEqualToString:@"CD0000"] || [self.code isEqualToString:@"CD000000"] || [self.code isEqualToString:@"UM0000"] || [self.code isEqualToString:@"MB0000"] || [self.code isEqualToString:@"MP000000"] || [self.code isEqualToString:@"CA0000"] || [self.code isEqualToString:@"PP0000"] || [self.code isEqualToString:@"PP000000"] || [self.code isEqualToString:@"QP0000"]; // QP0000极速付接口成功
}

- (BOOL)isNeedThrottle {
    if (!self.code) {
        return NO;
    }
    
    NSString *subCode;
    if (self.code.length >= 2) {
        subCode = [self.code substringFromIndex:2];
    }
    
    return Check_ValidString(subCode) && [subCode hasPrefix:@"4009"];
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"code": @"response.code",
        @"msg": @"response.msg",
        @"status": @"response.status",
        @"version": @"version",
        @"sign": @"sign",
        @"isFromCache": @"from_cache",
        @"responseDuration" :@"response_duration",
        @"errorType":@"err_type",
        @"typeContent":@"typecnt"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (NSMutableDictionary *)basicDict {
    return [@{@"code": @"response.code",
              @"msg": @"response.msg",
              @"status": @"response.status",
              @"version": @"version",
              @"sign": @"sign",
              @"isFromCache": @"from_cache",
              @"responseDuration" :@"response_duration",
              @"errorType":@"err_type",
              @"typeContent":@"typecnt"
            } mutableCopy];
}

@end
