// Copyright 2020 The Lynx Authors. All rights reserved.

#import "BDLExceptionReporter.h"
#import "BDLHostProtocol.h"
#import "BDLSDKManager.h"
#import "LynxVersion.h"
#import "NSDictionary+BDLynxAdditions.h"

@implementation BDLExceptionReporter

static BDLExceptionReporter *_instance = nil;

+ (instancetype)shareInstance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init];
  });
  return _instance;
}

+ (void)reportException:(NSError *)error {
  // Report app error to slardar app
  NSString *errorMessage = [error.userInfo bdlynx_stringValueForKey:@"message"];
  NSData *errorData = [errorMessage dataUsingEncoding:NSUTF8StringEncoding];
  NSError *parseErr;
  NSMutableDictionary *errorDict =
      [NSJSONSerialization JSONObjectWithData:errorData
                                      options:NSJSONReadingMutableContainers
                                        error:&parseErr];
  if (parseErr) {
    return;
  }
  NSString *errorType = @"LynxException";
  NSString *errorStack = errorDict[@"error"];

  NSDictionary *filterMap = @{
    @"code" : [[NSNumber numberWithLong:error.code] stringValue],
    @"url" : [errorDict valueForKey:@"url"] ?: @"",
  };

  void (^b)(NSError *_Nullable error) = ^void(NSError *_Nullable error) {
    if (error != nil) {
      NSLog(@"reportException error with %@", [error localizedDescription]);
    } else {
      NSLog(@"reportException success");
    }
  };

  // Use reflection to call
  NSArray *objs =
      [NSArray arrayWithObjects:errorType, errorStack, errorDict, filterMap, [b copy], nil];
  Class trackerClazz = NSClassFromString(@"HMDUserExceptionTracker");
  if (trackerClazz == nil) {
    NSLog(@"HMDUserExceptionTracker not exist");
    return;
  }
  if (![trackerClazz respondsToSelector:@selector(sharedTracker)]) {
    NSLog(@"sharedTracker not exist in HMDUserExceptionTracker");
    return;
  }
  id trackerInstance = [trackerClazz performSelector:@selector(sharedTracker)];
  SEL signatureSel =
      NSSelectorFromString(@"trackUserExceptionWithType:Log:CustomParams:filters:callback:");
  NSMethodSignature *signature =
      [[trackerInstance class] instanceMethodSignatureForSelector:signatureSel];
  if (signature == nil) {
    return;
  }
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = trackerInstance;
  invocation.selector = signatureSel;

  NSInteger paramsCount = signature.numberOfArguments - 2;
  paramsCount = MIN(paramsCount, objs.count);
  for (NSInteger i = 0; i < paramsCount; i++) {
    id object = objs[i];
    if ([object isKindOfClass:[NSNull class]]) continue;
    [invocation setArgument:&object atIndex:i + 2];
  }
  [invocation invoke];
}

+ (NSString *)backtraceWithMessage:(NSString *)message bySkippedDepth:(NSUInteger)skippedDepth {
  Class backtraceClazz = NSClassFromString(@"HMDAppleBacktracesLog");
  if (backtraceClazz == nil) {
    NSLog(@"HMDAppleBacktracesLog not exist");
    return nil;
  }
  SEL signatureSel = @selector(getCurrentThreadLogBySkippedDepth:logType:);
  NSMethodSignature *signature = [backtraceClazz methodSignatureForSelector:signatureSel];
  if (signature == nil) {
    return nil;
  }

  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
  invocation.target = backtraceClazz;
  invocation.selector = signatureSel;
  skippedDepth = skippedDepth + 1;
  NSUInteger logType = 6;
  [invocation setArgument:&skippedDepth atIndex:2];
  [invocation setArgument:&logType atIndex:3];
  [invocation invoke];
  id __unsafe_unretained returnValue = nil;
  if (signature.methodReturnLength) {
    [invocation getReturnValue:&returnValue];
  }
  if (returnValue == nil) {
    return nil;
  }
  NSString *appLog = [NSString stringWithFormat:@"UserExceptionType:%@\n%@", message, returnValue];
  return appLog;
}

@end
