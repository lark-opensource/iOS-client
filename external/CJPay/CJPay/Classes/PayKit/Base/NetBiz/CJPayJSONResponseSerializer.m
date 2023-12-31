//
//  CJPayJSONResponseSerializer.m
//  CJPay
//
//  Created by 王新华 on 2018/11/13.
//

#import "CJPayJSONResponseSerializer.h"

@implementation CJPayJSONResponseSerializer

- (instancetype)init
{
    if ((self = [super init])) {
        self.acceptableContentTypes = [NSSet setWithObjects:
                                       @"application/json",
                                       @"text/json",
                                       @"text/javascript",
                                       @"application/octet-stream",
                                       @"text/html",
                                       @"text/plain",
                                       nil];
    }
    return self;
}

- (id)responseObjectForResponse:(TTHttpResponse *)response
                        jsonObj:(id)jsonObj
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError{
    if (responseError) {
        if (resultError) {
            *resultError = responseError;
            [self error:resultError addHTTPStatusCodeWithResponse:response];
        }
        return nil;
    }
    if ([jsonObj isKindOfClass:[NSData class]]) {
        
        //stream里 对data有混淆 所以上面一步先位运算处理一下 下面再解析
        jsonObj = [super responseObjectForResponse:response jsonObj:jsonObj responseError:responseError resultError:resultError];
    }
    
    NSError *parseError = nil;
    
    if (![jsonObj isKindOfClass:[NSDictionary class]]) {
        if (resultError) {
            [self error:resultError addHTTPStatusCodeWithResponse:response];
        }
        return jsonObj;
    }
    
    if (parseError) {
        if (resultError) {
            *resultError = parseError;
            [self error:resultError addHTTPStatusCodeWithResponse:response];
        }
        return jsonObj;
    }
    
    return jsonObj;
}

- (void)error:(NSError*__autoreleasing *)error addHTTPStatusCodeWithResponse:(TTHttpResponse *)response {
    if (error == nil || *error == nil || ![response isKindOfClass:[TTHttpResponse class]]) {
        return;
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:5];
    if ((*error).userInfo.count > 0) {
        [userInfo addEntriesFromDictionary:(*error).userInfo];
    }
    [userInfo setValue:@(response.statusCode) forKey:@"code"];
    *error = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
}

- (NSSet *)acceptableContentTypes {
    return self.acceptableContentTypes;
}

+ (NSObject<TTJSONResponseSerializerProtocol> *)serializer
{
    return [[[self class] alloc] init];
}

@end
