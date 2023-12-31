//
//  TTHttpResponseChromium.m
//  Pods
//
//  Created by gaohaidong on 11/16/16.
//
//

#import "TTHttpResponseChromium.h"
#import "TTNetworkManagerLog.h"
#import "TTNetworkUtil.h"
#include "net/url_request/url_fetcher.h"
//#include "net/url_request/url_request.h"
#include "net/http/http_response_headers.h"
#include "base/strings/sys_string_conversions.h"
#include "base/time/time.h"

@interface TTHttpResponseChromiumTimingInfo ()

@property (nonatomic, strong, readwrite) NSDate *start;
@property (nonatomic, assign, readwrite) int64_t proxy;
@property (nonatomic, assign, readwrite) int64_t dns;
@property (nonatomic, assign, readwrite) int64_t connect;
@property (nonatomic, assign, readwrite) int64_t ssl;
@property (nonatomic, assign, readwrite) int64_t send;
@property (nonatomic, assign, readwrite) int64_t wait;
@property (nonatomic, assign, readwrite) int64_t receive;
@property (nonatomic, assign, readwrite) int64_t total;

@property (nonatomic, assign, readwrite) int64_t receivedResponseContentLength;
@property (nonatomic, assign, readwrite) int64_t totalReceivedBytes;

@property (nonatomic, assign, readwrite) BOOL isSocketReused;
@property (nonatomic, assign, readwrite) BOOL isCached;
@property (nonatomic, assign, readwrite) int8_t cacheStatus;
@property (nonatomic, assign, readwrite) BOOL isFromProxy;
@property (nonatomic, copy,   readwrite) NSString *remoteIP;
@property (nonatomic, assign, readwrite) uint16_t remotePort;

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher;

@end

@interface TTHttpResponseChromium ()

@property (atomic, nullable, strong) TTCaseInsenstiveDictionary *allHeaders;
@property (atomic, assign) NSInteger httpStatusCode;
@property (atomic, copy) NSURL *httpURL;
@property (atomic, strong, readwrite) BDTuringCallbackInfo *turingCallbackInfo;
@property (atomic, strong, readwrite) TTHttpResponseChromiumTimingInfo *timingInfo;
@property (atomic, copy, readwrite) NSString *requestLog;
@property (atomic, assign) BOOL isHttpInternalRedirect;

@end

@implementation TTHttpResponseChromium

@synthesize requestLog = _requestLog;
@synthesize turingCallbackInfo = _turingCallbackInfo;

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher {
    self = [super init];
    if (self) {
        //TODO: assert fetcher is not in IO_PENDING state
        
        TTCaseInsenstiveDictionary *headers = [[TTCaseInsenstiveDictionary alloc] init];
        
        const auto &response_headers = fetcher->GetResponseHeaders();
        
        if (response_headers) {
            size_t iter = 0;
            std::string name;
            std::string value;
            while (response_headers->EnumerateHeaderLines(&iter, &name, &value)) {
                NSString *k = base::SysUTF8ToNSString(name);
                NSString *v = base::SysUTF8ToNSString(value);
                if (!k || !v) {
                    continue;
                }

                NSString *current = [headers objectForKey:k];
                if (current) {
                    v = [NSString stringWithFormat:@"%@, %@", current, v];
                }
                //LOGE(@"header key = %@, v = %@", k, v);
                if (k && v) {
                    [headers setValue:v forKey:k];
                }
            }
        }
        
        self.allHeaders = headers;
        
        self.httpStatusCode = fetcher->GetResponseCode();
        
        const GURL &url= fetcher->GetOriginalURL(); // GetURL() is current URL, this is the orginal one
        const auto &url_string = url.spec();
        self.httpURL = [NSURL URLWithString:base::SysUTF8ToNSString(url_string)];
        
        self.timingInfo = [[TTHttpResponseChromiumTimingInfo alloc] initWithURLFetcher:fetcher];
        self.requestLog = @(fetcher->GetRequestLog().c_str());
    }
    return self;
}

- (NSString *)requestLog {
    return _requestLog;
}

- (void)setRequestLog:(NSString *)requestLog {
    _requestLog = [TTNetworkUtil addComponentVersionToRequestLog:requestLog];
}

- (void)appendRequestLogWithCompressLog:(NSString *)compressLog {
    _requestLog = [TTNetworkUtil addCompressLogToRequestLog:self.requestLog compressLog:compressLog];
}

- (instancetype)initWithRequestLog:(NSString *)requestLog {
    self = [super init];
    if (self) {
        self.requestLog = requestLog;
    }
    return self;
}

- (instancetype)initWithRedirectedInfo:(NSString *)current_url
                          new_location:(NSString *)new_location
                           status_code:(int)status_code
                      response_headers:(TTCaseInsenstiveDictionary*)response_headers
                  is_internal_redirect:(BOOL)is_internal_redirect {
  self = [super init];
  if (self) {
    self.httpURL = [NSURL URLWithString:current_url];
    self.httpStatusCode = status_code;
    self.allHeaders = response_headers;
    self.isHttpInternalRedirect = is_internal_redirect;
  }
  return self;
}

- (void)dealloc {
    LOGD(@"%s %p", __FUNCTION__, self);
}

- (NSInteger)statusCode {
    return self.httpStatusCode;
}

- (TTCaseInsenstiveDictionary *)allHeaderFields {
    return self.allHeaders;
}

- (NSURL *)URL {
    return self.httpURL;
}

- (NSString *)MIMEType {
    NSString *type = self.allHeaders[@"Content-Type"];
    if (type) {
        return type;
    }
    
    for (NSString *key in [self.allHeaders allKeys]) {
        if ([[key lowercaseString] isEqualToString: [@"Content-Type" lowercaseString]]) {
            return self.allHeaders[key];
        }
    }
    return nil;
}

- (BOOL)isInternalRedirect {
    return self.isHttpInternalRedirect;
}

- (TTHttpResponseChromiumTimingInfo *)timinginfo {
    return self.timingInfo;
}

- (BDTuringCallbackInfo *)turingCallbackinfo {
    return self.turingCallbackInfo;
}

- (void)setTuringCallbackRelatedInfo:(BDTuringCallbackInfo *)turingCallbackInfo {
    _turingCallbackInfo = turingCallbackInfo;
}

@end

#pragma mark - TTHttpResponseChromiumTimingInfo

@implementation TTHttpResponseChromiumTimingInfo

@synthesize start = _start;
@synthesize proxy = _proxy;
@synthesize dns = _dns;
@synthesize connect = _connect;
@synthesize ssl = _ssl;
@synthesize send = _send;
@synthesize wait = _wait;
@synthesize receive = _receive;
@synthesize total = _total;
@synthesize receivedResponseContentLength = _receivedResponseContentLength;
@synthesize totalReceivedBytes = _totalReceivedBytes;
@synthesize isSocketReused = _isSocketReused;
@synthesize isCached = _isCached;
@synthesize cacheStatus = _cacheStatus;
@synthesize isFromProxy = _isFromProxy;
@synthesize remoteIP = _remoteIP;
@synthesize remotePort = _remotePort;

- (instancetype)initWithURLFetcher:(const net::URLFetcher *)fetcher {
    self = [super init];
    if (self) {
        auto info = fetcher->GetLoadTimingInfo();
        if (info) {
            net::LoadTimingInfo::ConnectTiming con = info->connect_timing;
            auto dns = (con.dns_end - con.dns_start).InMilliseconds();
            
            auto connect_time = (con.connect_end - con.connect_start).InMilliseconds();
            
            auto ssl_time = (con.ssl_end - con.ssl_start).InMilliseconds();
            
            auto send_time = (info->send_end - info->send_start).InMilliseconds();
            
            self.dns = dns;
            self.connect = connect_time;
            self.ssl = ssl_time;
            self.send = send_time;
            
            self.proxy = (info->proxy_resolve_end - info->proxy_resolve_start).InMilliseconds();
            
            self.wait = (info->receive_headers_end - info->send_end).InMilliseconds();
            
            self.receive = (base::TimeTicks::Now() - info->receive_headers_end).InMilliseconds();
            
            auto now = base::Time::Now();
            base::TimeDelta total_time = now - info->request_start_time;
            
            self.total = total_time.InMilliseconds();
            
            self.isSocketReused = info->socket_reused;
            self.isCached = fetcher->WasCached();
            self.cacheStatus = fetcher->GetCacheStatus();
            self.isFromProxy = fetcher->WasFetchedViaProxy();

            const auto &pair = fetcher->GetSocketAddress();
            self.remoteIP = @(pair.ToStringWithoutPort().c_str());
            self.remotePort = pair.port();
            
            self.start = [NSDate dateWithTimeIntervalSince1970:(info->request_start_time).ToDoubleT()];
            
            
            self.receivedResponseContentLength = fetcher->GetReceivedResponseContentLength();
            self.totalReceivedBytes = fetcher->GetTotalReceivedBytes();
            
            const auto &url = fetcher->GetOriginalURL();
            const auto &path = url.path();
            const auto &url_string = url.spec();
            
            if (path.find("feed/v") != std::string::npos) {
                LOGI(@"url = %@, dns time = %lld, connect time = %lld, ssl connect time = %lld, send time = %lld, self.receivedResponseContentLength = %lld, self.remoteIP = %@, self.remotePort = %d, self.totalReceivedBytes = %lld, isSocketReused = %d, self.isCached = %d, self.cacheStatus = %d, self.isFromProxy = %d, total time = %lld, wait time = %lld, receive time = %lld ms, proxy time = %lld", @(url_string.c_str()), self.dns, self.connect, ssl_time, send_time, self.receivedResponseContentLength, self.remoteIP, self.remotePort, self.totalReceivedBytes, self.isSocketReused, self.isCached, self.cacheStatus, self.isFromProxy, self.total, self.wait, self.receive, self.proxy);
            }
            
        }
    }
    return self;
}

@end
