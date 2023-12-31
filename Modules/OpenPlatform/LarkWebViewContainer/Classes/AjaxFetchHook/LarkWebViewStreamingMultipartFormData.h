#import <Foundation/Foundation.h>
#import "LarkWebViewMultipartFormData.h"

NS_ASSUME_NONNULL_BEGIN

@interface LarkWebViewStreamingMultipartFormData : NSObject<LarkWebViewMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

NS_ASSUME_NONNULL_END
