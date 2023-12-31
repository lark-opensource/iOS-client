// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_LYNXERROR_H_
#define DARWIN_COMMON_LYNX_LYNXERROR_H_

#import "LynxErrorCode.h"

NS_ASSUME_NONNULL_BEGIN

/// LynxError's domain.
FOUNDATION_EXPORT NSString* const LynxErrorDomain;

#pragma mark - LynxError UserInfo
FOUNDATION_EXPORT NSString* const LynxErrorUserInfoKeyMessage;
FOUNDATION_EXPORT NSString* const LynxErrorUserInfoKeySourceError;
FOUNDATION_EXPORT NSString* const LynxErrorUserInfoKeyCustomInfo;
FOUNDATION_EXPORT NSString* const LynxErrorUserInfoKeyStackInfo;

/// LynxError's level
FOUNDATION_EXPORT NSString* const LynxErrorLevelError;
FOUNDATION_EXPORT NSString* const LynxErrorLevelWarn;

// LynxError instance is not thread safe,
// should not use it in multi thread
@interface LynxError : NSError

/** Required fields */
// error code for the error
@property(nonatomic, readonly) NSInteger errorCode;
// a summary message of the error
@property(nonatomic, readonly) NSString* summaryMessage;
// url of the template that reported the error
@property(nonatomic, readwrite) NSString* templateUrl;
// version of the card that reported the error
@property(nonatomic, readwrite) NSString* cardVersion;
// error level, can take value LynxErrorLevelError or LynxErrorLevelWarn
@property(nonatomic, readonly) NSString* level;

/** Optional fields */
// fix suggestion for the error
@property(nonatomic, readonly) NSString* fixSuggestion;
// the call stack when the error occurred
@property(nonatomic, readwrite) NSString* callStack;

/** Custom fields */
// some custom info of the error
@property(nonatomic, readonly) NSMutableDictionary* customInfo;

+ (instancetype)lynxErrorWithCode:(NSInteger)code
                          message:(NSString*)errorMsg
                    fixSuggestion:(NSString*)suggestion
                            level:(NSString*)level;
+ (instancetype)lynxErrorWithCode:(NSInteger)code
                          message:(NSString*)errorMsg
                    fixSuggestion:(NSString*)suggestion
                            level:(NSString*)level
                       customInfo:(NSDictionary* _Nullable)customInfo;

- (BOOL)isValid;

- (void)addCustomInfo:(NSString*)value forKey:(NSString*)key;

// deprecated
+ (instancetype)lynxErrorWithCode:(NSInteger)code message:(NSString*)message;
+ (instancetype)lynxErrorWithCode:(NSInteger)code sourceError:(NSError*)source;
+ (instancetype)lynxErrorWithCode:(NSInteger)code userInfo:(NSDictionary*)userInfo;

// mainly for create NSError conveniently
+ (instancetype)lynxErrorWithCode:(NSInteger)code description:(nonnull NSString*)message;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_LYNXERROR_H_
