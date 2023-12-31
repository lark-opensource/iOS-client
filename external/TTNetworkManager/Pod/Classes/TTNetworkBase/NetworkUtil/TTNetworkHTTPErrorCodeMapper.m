//
//  TTNetworkHTTPErrorCodeMapper.m
//  Pods
//
//  Created by Dai Dongpeng on 5/1/16.
//
//

#import "TTNetworkHTTPErrorCodeMapper.h"
#import "TTNetworkDefine.h"
#import <errno.h>

#ifdef _TTNumberString(a)
#undef _TTNumberString(a)
#else 
#define _TTNumberString(a) [@(a) stringValue]
#endif

@implementation TTNetworkHTTPErrorCodeMapper

+ (NSInteger)mapErrorCode:(NSInteger)code
{
    NSNumber *n = [[self getCodeMapper] objectForKey:[self keyForCode:code]];
    if (n) {
        return [n integerValue];
    }
    return NSNotFound;
}

+ (NSInteger)mapErrno:(NSInteger)errorno
{
    NSNumber *n = [[self getErrnoMapper] objectForKey:[self keyForErrno:errorno]];
    if (n) {
        return [n integerValue];
    }
    return NSNotFound;
}

+ (NSInteger)unknonwErrorMapcode;
{
    return [[[self getCodeMapper] objectForKey:[self keyForCode:kCFURLErrorUnknown]] integerValue];
}

+ (NSString *)keyForCode:(NSInteger)code
{
    return _TTNumberString(code);
}

+ (NSString *)keyForErrno:(NSInteger)errorno
{
    return _TTNumberString(errorno);
}

+ (NSDictionary *)getCodeMapper {
    static NSDictionary* codeMapper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        codeMapper =
        @{
          _TTNumberString(kCFURLErrorUnknown) : @(TTNetworkErrorCodeUnknown),
          _TTNumberString(kCFURLErrorTimedOut) : @(TTNetworkErrorCodeConnectTimeOut),
          
          // _TTNumberString(1) : @(TTNetworkErrorCodeSocketTimeOut),//
          
          //The following are unified to IO-Exception
          _TTNumberString(kCFURLErrorCannotCreateFile) : @(TTNetworkErrorCodeIOException),
          _TTNumberString(kCFURLErrorCannotOpenFile) : @(TTNetworkErrorCodeIOException),
          _TTNumberString(kCFURLErrorCannotCloseFile) : @(TTNetworkErrorCodeIOException),
          _TTNumberString(kCFURLErrorCannotWriteToFile) : @(TTNetworkErrorCodeIOException),
          _TTNumberString(kCFURLErrorCannotRemoveFile) : @(TTNetworkErrorCodeIOException),
          _TTNumberString(kCFURLErrorCannotMoveFile) : @(TTNetworkErrorCodeIOException),
          
          // _TTNumberString(1) : @(TTNetworkErrorCodeSocketException),//
          // _TTNumberString(1) : @(TTNetworkErrorCodeResetByPeer),
          // _TTNumberString(1) : @(TTNetworkErrorCodeBindException),
          
          _TTNumberString(kCFURLErrorNetworkConnectionLost) : @(TTNetworkErrorCodeConnectExceptioin),
          
          _TTNumberString(kCFURLErrorDNSLookupFailed) : @(TTNetworkErrorCodeNoReouteToHost),
          
          // _TTNumberString(1) : @(TTNetworkErrorCodeProtUnreachable),
          
          _TTNumberString(kCFURLErrorCannotFindHost) : @(TTNetworkErrorCodeUnknonwHost),
          
          // 12 - 17 : errno
          
          // bad & Cannotparse all Normalize to No response
          _TTNumberString(kCFURLErrorBadServerResponse) : @(TTNetworkErrorCodeNoHttpResponse),
          _TTNumberString(kCFURLErrorCannotParseResponse) : @(TTNetworkErrorCodeNoHttpResponse),
          
          _TTNumberString(kCFURLErrorUnsupportedURL) : @(TTNetworkErrorCodeClientProtocolException),
          
          _TTNumberString(kCFURLErrorDataLengthExceedsMaximum) : @(TTNetworkErrorCodeFileTooLarge),
          
          _TTNumberString(kCFURLErrorHTTPTooManyRedirects) : @(TTNetworkErrorCodeTooManyRedirect),
          
          //cancelled -> ClientError
          _TTNumberString(kCFURLErrorCancelled) : @(TTNetworkErrorCodeUnknowClientError),
          
          //32 - 37 : errno
          };
    });
    
    return codeMapper;
}

+ (NSDictionary *)getErrnoMapper {
    static NSDictionary* errnoMapper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        errnoMapper =
        @{
          // 12 - 17 : errno
          _TTNumberString(ECONNRESET) : @(TTNetworkErrorCodeECONNRESET),
          
          _TTNumberString(ECONNREFUSED) : @(TTNetworkErrorCodeECONNREFUSED),
          
          _TTNumberString(EHOSTUNREACH) : @(TTNetworkErrorCodeEHOSTUNREACH),
          
          _TTNumberString(ENETUNREACH) : @(TTNetworkErrorCodeENETUNREACH),
          
          _TTNumberString(EADDRNOTAVAIL) : @(TTNetworkErrorCodeEADDRNOTAVAIL),
          
          _TTNumberString(EADDRINUSE) : @(TTNetworkErrorCodeEADDRINUSE),
          
          //32 - 37 : errno
          
          _TTNumberString(ENOBUFS) : @(TTNetworkErrorCodeNoSpace),
          _TTNumberString(ENOSPC) : @(TTNetworkErrorCodeNoSpace),
          
          _TTNumberString(ENOENT) : @(TTNetworkErrorCodeENOENT),
          
          _TTNumberString(EDQUOT) : @(TTNetworkErrorCodeEDQUOT),
          
          _TTNumberString(EROFS) : @(TTNetworkErrorCodeEROFS),
          
          _TTNumberString(EACCES) : @(TTNetworkErrorCodeEACCES),
          
          };
    });
    
    return errnoMapper;
}

@end
