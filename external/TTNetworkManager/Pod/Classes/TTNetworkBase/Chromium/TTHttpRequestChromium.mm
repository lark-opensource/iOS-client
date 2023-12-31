//
//  TTHttpRequestChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHttpRequestChromium.h"
#import "TTNetworkUtil.h"
#import "TTNetworkManagerLog.h"

#pragma mark - new auth credentials object
@implementation TTAuthCredentials
- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
    if (self = [super init]) {
        self.username = username;
        self.password = password;
    }
    return self;
}
@end

@interface TTHttpRequest()
@property (nullable, readwrite, copy) NSDictionary *webviewInfo;
@end

@interface TTHttpRequestChromium ()
@property (atomic, assign) BOOL enableCaseInsensitiveHeader;
@property (atomic, copy) NSString *method;
@property (atomic, copy) NSData *body;
@property (atomic, strong) NSMutableDictionary<NSString *, NSString *> *allHTTPHeaders;
@property (atomic, strong) TTCaseInsenstiveDictionary<NSString *, NSString *> *caseInsensitiveAllHTTPHeaders;
@property (atomic, assign) NSTimeInterval timeout;
@end

@implementation TTHttpRequestChromium

- (instancetype)initWithURL:(NSString *)url method:(NSString *)method multipartForm:(TTHttpMultipartFormDataChromium *)form {
    if (self = [super init]) {
        self.urlString = url;
        self.HTTPMethod = method;
        self.form = form;
        self.timeout = g_request_timeout;
        self.requestQueryPriority = 0;
        self.pureRequest = NO;
        self.enableCaseInsensitiveHeader = [TTNetworkManager shareInstance].enableRequestHeaderCaseInsensitive;
    }
    return self;
}

- (void)dealloc {
    LOGD(@"%p", self);
}

#pragma mark - getter/setters

- (NSURL *)URL {
    NSURL *result = [NSURL URLWithString:self.urlString];
    if (!result) {
        result = [NSURL URLWithString:[self.urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return result;
}

- (void)setURL:(NSURL *)URL {
    [super setURL:URL];
    self.urlString = [URL absoluteString];
}

- (NSTimeInterval)timeoutInterval {
    return self.timeout;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    self.timeout = timeoutInterval;
}


- (NSData *)HTTPBody {
    return self.body;
}

- (void)setHTTPBody:(NSData *)HTTPBody {
  @try {
    self.body = HTTPBody;
  } @catch (NSException *exception) {
    _body = HTTPBody;
  }
}

- (void)setHTTPBodyNoCopy:(NSData *)HTTPBody {
    _body = HTTPBody;
}

- (NSDictionary<NSString *, NSString *> *)allHTTPHeaderFields {
    if (self.enableCaseInsensitiveHeader) {
        return self.caseInsensitiveAllHTTPHeaders;
    }
    return self.allHTTPHeaders;
}

- (void)setAllHTTPHeaderFields:(NSMutableDictionary<NSString *,NSString *> *)allHTTPHeaderFields {
    if (self.enableCaseInsensitiveHeader) {
        self.caseInsensitiveAllHTTPHeaders = [[TTCaseInsenstiveDictionary alloc] initWithDictionary:allHTTPHeaderFields];
    } else {
        self.allHTTPHeaders = [[NSMutableDictionary alloc] initWithDictionary:allHTTPHeaderFields];
    }
}

#pragma mark - http headers

- (void)validateHTTPHeaders {
    if (self.enableCaseInsensitiveHeader) {
        if (!self.caseInsensitiveAllHTTPHeaders) {
            self.caseInsensitiveAllHTTPHeaders = [[TTCaseInsenstiveDictionary alloc] init];
        }
        if (![self.caseInsensitiveAllHTTPHeaders isKindOfClass:TTCaseInsenstiveDictionary.class]) {
            self.caseInsensitiveAllHTTPHeaders = [[TTCaseInsenstiveDictionary alloc] initWithDictionary:self.caseInsensitiveAllHTTPHeaders];
        }
    } else {
        if (!self.allHTTPHeaders) {
            self.allHTTPHeaders = [[NSMutableDictionary alloc] init];
        }
        if (![self.allHTTPHeaders isKindOfClass:NSMutableDictionary.class]) {
            self.allHTTPHeaders = [[NSMutableDictionary alloc] initWithDictionary:self.allHTTPHeaders];
        }
    }
}

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field {
    [self validateHTTPHeaders];
    if (self.enableCaseInsensitiveHeader) {
        [self.caseInsensitiveAllHTTPHeaders setValue:value forKey:field];
    } else {
        [self.allHTTPHeaders setValue:value forKey:field];
    }
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self validateHTTPHeaders];
    NSString *insertValue = value;
    NSDictionary* dict = self.enableCaseInsensitiveHeader ? self.caseInsensitiveAllHTTPHeaders : self.allHTTPHeaders;
    NSString *oldValue = [dict objectForKey:field];
    if (oldValue) {
        insertValue = [NSString stringWithFormat:@"%@,%@",oldValue,value];
    }
    [dict setValue:insertValue forKey:field];
}

- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field {
    if (self.caseInsensitiveAllHTTPHeaders) {
        return [self.caseInsensitiveAllHTTPHeaders valueForKey:field];
    }
    return [self.allHTTPHeaders valueForKey:field];
}

#pragma mark - webview info for slardar

- (void)setWebviewInfoProperty:(NSDictionary *)webviewInfo {
    self.webviewInfo = webviewInfo;
}

@end
