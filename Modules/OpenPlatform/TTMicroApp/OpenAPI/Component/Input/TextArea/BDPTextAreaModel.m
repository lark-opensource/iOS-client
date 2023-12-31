//
//  BDPTextAreaModel.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/4.
//

#import <Foundation/Foundation.h>

#import "BDPTextAreaModel.h"
#import <OPFoundation/BDPUtils.h>

#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation BDPTextAreaModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    // 以下3个参数只有showTextAreaKeyboard时会单独传输，单独使用，并非来自JSON的全量解析
    if ([propertyName isEqualToString:@"cursor"]) {
        return YES;
    } else if ([propertyName isEqualToString:@"selectionStart"]) {
        return YES;
    } else if ([propertyName isEqualToString:@"selectionEnd"]) {
        return YES;
    }
    return NO;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    @try {
        self = [super initWithDictionary:dict error:err];
    } @catch (NSException *exception) {
        /** FIXME:  JSONModel 内部类型处理不当会导致 Crash
            Github issue:   https://github.com/jsonmodel/jsonmodel/issues/624
            若布尔类型属性传入 js object:    { } ，则会导致 JSONModel 内部崩溃。
            原因是 JSONModle将 { } 解析为 NSDictionary，并且会调用其 boolValue 方法，从而导致 Crash：「 unrecognized selector send to instance 」
         */
        BDPLogError(@"BDPBaseJSONModel init failed! %@", exception);
        NSMutableDictionary * info = [NSMutableDictionary dictionary];
        [info setValue:exception.name forKey:@"ExceptionName"];
        [info setValue:exception.reason forKey:@"ExceptionReason"];
        [info setValue:exception.callStackReturnAddresses forKey:@"ExceptionCallStackReturnAddresses"];
        [info setValue:exception.callStackSymbols forKey:@"ExceptionCallStackSymbols"];
        [info setValue:exception.userInfo forKey:@"ExceptionUserInfo"];
        // code占位，无意义
        *err = [NSError errorWithDomain:@"JSONMODEL_INIT_FAIL" code:-1 userInfo:info];
    }
    if (*err) {
        BDPLogError(@"BDPBaseJSONModel init failed! %@", *err);
        return nil;
    }
    if (self) {
        // 三个参数默认值设置为-1，不进行选中位置的设置
        // 默认值为0会造成光标跑到第一位，因此需要设置-1
        self.cursor = -1;
        self.selectionStart = -1;
        self.selectionEnd = -1;
        NSString *adjustPositionStr = [dict bdp_stringValueForKey:@"adjustPosition"];
        if (BDPIsEmptyString(adjustPositionStr)) {
            self.adjustPosition = YES;
        }
    }
    return self;
}

@end
