//
//  TTHttpMultipartFormDataChromium.h
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHttpMultipartFormData.h"

@class TTHttpRequestChromium;

@interface TTHttpMultipartFormDataChromium : TTHttpMultipartFormData

- (NSData *)finalFormDataWithHttpRequest:(TTHttpRequestChromium *)request;
- (NSString *)getContentType;

@end
