//
//  TTHttpRequestChromium.h
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import <Foundation/Foundation.h>
#import "TTHttpRequest.h"
#import "TTHttpMultipartFormDataChromium.h"

@interface TTHttpRequestChromium : TTHttpRequest

@property (atomic, strong) TTHttpMultipartFormDataChromium *form;
@property (atomic, copy) NSString *urlString;
@property (atomic, strong) NSDictionary *params;
//used for query filter engine
@property (atomic, assign) NSInteger requestQueryPriority;

//used for define pure request
@property (atomic, assign) BOOL pureRequest;


- (instancetype)initWithURL:(NSString *)url method:(NSString *)method multipartForm:(TTHttpMultipartFormDataChromium *)form;
- (void)setHTTPBodyNoCopy:(NSData *)HTTPBody;
- (void)setWebviewInfoProperty:(NSDictionary *)webviewInfo;
@end
