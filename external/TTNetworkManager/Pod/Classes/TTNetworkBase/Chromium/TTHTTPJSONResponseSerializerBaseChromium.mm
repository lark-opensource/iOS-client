//
//  TTHTTPJSONResponseSerializerBaseChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHTTPJSONResponseSerializerBaseChromium.h"

#import "TTHttpResponseChromium.h"
#import "TTNetworkManagerLog.h"

//NSString * const KTTHTTPJSONResponseSerializerBaseChromiumDomain = @"KTTHTTPJSONResponseSerializerBaseChromiumDomain";

@interface TTHTTPJSONResponseSerializerBaseChromium ()

@property (nonatomic, strong) NSSet *acceptableContentTypeSet;
@property (nonatomic, strong) NSMutableIndexSet *acceptableStatusCodes;

@end

@implementation TTHTTPJSONResponseSerializerBaseChromium

- (instancetype)init {
    self = [super init];
    if (self) {
        //self.acceptableContentTypeSet = [[NSMutableSet alloc] init];
        self.acceptableStatusCodes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

+ (NSObject<TTJSONResponseSerializerProtocol> *)serializer {
    return [[TTHTTPJSONResponseSerializerBaseChromium alloc] init];
}

- (id)responseObjectForResponse:(TTHttpResponse *)response
                        jsonObj:(id)jsonObj
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError {
    
    if (responseError) {
        *resultError = responseError;
        return nil;
    }
    
//    TTHttpResponseChromium *targetResponse = nil;
//    // Convert TTHttpResponse to TTHttpResponseChromium
//    if ([response isKindOfClass:TTHttpResponseChromium.class]) {
//        targetResponse = (TTHttpResponseChromium *)response;
//    } else {
//        NSAssert(NO, @"should be a TTHttpResponseChromium instance");
//        if (resultError) {
//            *resultError = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeUnknowClientError userInfo:nil];
//        }
//        return nil;
//    }

    if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode] && [response URL]) {
        LOGE(@"server response code is wrong, response code = %ld, url = %@", (long)response.statusCode, [response URL]);
        NSMutableDictionary *mutableUserInfo = [@{
                                                  NSLocalizedDescriptionKey : [NSString stringWithFormat:@"server response code (%ld) is not 2xx.", (long)response.statusCode],
                                                  NSURLErrorFailingURLErrorKey :[response URL],
                                                  @"com.alamofire.serialization.response.error.response" : response,
                                                  } mutableCopy];
        
        if (jsonObj) {
            mutableUserInfo[@"jsonObj"] = jsonObj;
        }
        
        if (resultError) {
            *resultError = [NSError errorWithDomain:kTTNetworkErrorDomain code:NSURLErrorBadServerResponse userInfo:mutableUserInfo];
        }
        
        return nil;
    }
    
    NSString *mime = [response MIMEType];
    
    NSUInteger location = [mime.lowercaseString rangeOfString:@";"].location;
    if (location != NSNotFound) {
        mime = [mime.lowercaseString substringToIndex:location];
    }
    if (self.acceptableContentTypeSet && ![self.acceptableContentTypeSet containsObject:mime]) {
        
        if (resultError) {
            NSString *error = [NSString stringWithFormat:@"Unexpected MIME:%@, expected MIME:%@", mime, self.acceptableContentTypeSet];
            NSDictionary *userInfo = nil;
            NSString *nilResponseUrl = nil;
            NSURL *responseUrl = [response URL];
            if (!responseUrl) {
                nilResponseUrl = @"[response URL] is nil";
                userInfo = @{NSLocalizedDescriptionKey : error, NSURLErrorFailingURLErrorKey :nilResponseUrl};
            } else {
                userInfo = @{NSLocalizedDescriptionKey : error, NSURLErrorFailingURLErrorKey :responseUrl};
            }
            
            *resultError = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeParseJSONError userInfo:userInfo];
        }
        LOGE(@"No MIME %@ found in acceptableContentTypes %@", mime, self.acceptableContentTypeSet);
        // return error
        return nil;
    }

    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        return jsonObj;
    }
    
    NSError *parseError = nil;
    NSData *jsonData = (NSData *)jsonObj;
    if (!jsonData) {
        LOGE(@"jsonData is nil");
        return nil;
    }
    id ret = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&parseError];
    
    if (parseError) {
        
        if (resultError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : parseError.localizedDescription, NSURLErrorFailingURLErrorKey :[response URL]};
            
            *resultError = [[NSError alloc] initWithDomain:kTTNetworkErrorDomain code:TTNetworkErrorCodeParseJSONError userInfo:userInfo];
        }
//        LOGE(@"error %@ in parsing json", parseError);
        return nil;
    }
    
    return ret;
}

- (NSSet *)acceptableContentTypes {
    return self.acceptableContentTypeSet;
}

- (void)setAcceptableContentTypes:(NSSet *)acceptableContentTypes {
    self.acceptableContentTypeSet = acceptableContentTypes;
}

@end
