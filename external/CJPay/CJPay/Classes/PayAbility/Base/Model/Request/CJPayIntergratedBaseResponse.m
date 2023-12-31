//
//  CJPayIntergratedBaseResponse.m
//  CJPay
//
//  Created by wangxinhua on 2020/9/9.
//

#import "CJPayIntergratedBaseResponse.h"
#import "CJPaySDKMacro.h"

@implementation CJPayIntergratedBaseResponse

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

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{}]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (BOOL)isSuccess {
    return [self.code isEqualToString:@"CA0000"];
}

+ (NSDictionary *)basicMapperWith:(NSDictionary *)newDic {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"code":@"code",
        @"errorType":@"error.type",
        @"typecnt":@"error.type_cnt",
        @"innerMsg": @"error.inner_msg",
        @"msg":@"error.msg",
        @"errorData":@"error.data",
        @"processStr":@"process",
        @"responseDuration": @"response_duration"
    }];
    [mutableDic addEntriesFromDictionary:newDic];
    return [mutableDic copy];
}

@end
