//
//  TTHTTPResponseSerializerBase.m
//  Pods
//
//  Created by gaohaidong on 9/28/16.
//
//

#import "TTHTTPResponseSerializerBase.h"

#import "TTNetworkManager.h"
#import "TTHTTPJSONResponseSerializerBaseChromium.h"

@interface TTHTTPJSONResponseSerializerBase()

@property (nonatomic, strong) NSObject<TTJSONResponseSerializerProtocol> *currentImpl;

@end

@implementation TTHTTPJSONResponseSerializerBase


+ (NSObject<TTJSONResponseSerializerProtocol> *)serializer
{
    return [[TTHTTPJSONResponseSerializerBase alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if ([TTNetworkManager getLibraryImpl] == TTNetworkManagerImplTypeLibChromium) {
            self.currentImpl = [TTHTTPJSONResponseSerializerBaseChromium serializer];
        } else {
            NSAssert(false, @"please set the underlining impl lib to TTNetworkManagerImplTypeLibChromium!");
        }
    }
    return self;
}

/**
 *  Parse TTHttpResponse
 *
 *  @param response      NSURLResponse object
 *  @param jsonObj       parsed JSON object（if can parse）
 *  @param responseError error returned
 *  @param resultError   error pass to bussiness layer
 *
 *  @return Parsed result
 */
- (id)responseObjectForResponse:(TTHttpResponse *)response
                        jsonObj:(id)jsonObj
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError{
    return [self.currentImpl responseObjectForResponse:response jsonObj:jsonObj responseError:responseError resultError:resultError];
}

- (NSSet *)acceptableContentTypes {
    return self.currentImpl.acceptableContentTypes;
}

- (void)setAcceptableContentTypes:(NSSet *)acceptableContentTypes {
    [self.currentImpl setAcceptableContentTypes:acceptableContentTypes];
}


@end
