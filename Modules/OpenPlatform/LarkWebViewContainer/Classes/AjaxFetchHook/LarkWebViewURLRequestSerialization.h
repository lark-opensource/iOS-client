#import <Foundation/Foundation.h>
#import "LarkWebViewStreamingMultipartFormData.h"

NS_ASSUME_NONNULL_BEGIN

@interface LarkWebViewURLRequestSerialization : NSObject

- (void)multipartFormRequestWithRequest:(NSMutableURLRequest *)mutableRequest
                             parameters:(NSDictionary *)parameters
              constructingBodyWithBlock:(void (^)(id <LarkWebViewMultipartFormData> formData))block
                                  error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
