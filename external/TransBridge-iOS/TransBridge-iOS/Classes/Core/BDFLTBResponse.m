//
//  TTRBridgeResponse.m
//  Runner
//
//  Copyright © 2020 Toutiao. All rights reserved.
//

#import "BDFLTBResponse.h"
#import "BDChannelJsonUtil.h"

@interface BDFLTBResponse()

@property (assign , nonatomic) NSInteger code;
@property (copy   , nonatomic) NSString *message;
@property (strong , nonatomic) id data;

@end

@implementation BDFLTBResponse

- (instancetype)initWithCode:(NSInteger)code message:(NSString *)message data:(id)data {
  if (self = [super init]) {
    _code = code;
    _message = message;
    _data = data;
  }
  return self;
}

- (BOOL)isError {
  return (self.code == FLTBResponseError);
}

- (BOOL)isNotImplement {
  return (self.code == FLTBResponseNotFound);
}

+ (instancetype)responseWithCode:(NSInteger)code message:(NSString *)message data:(NSDictionary *)data {
  BDFLTBResponse *response = [[BDFLTBResponse alloc] initWithCode:code message:message data:data];
  return response;
}

+ (instancetype)successResponseWithData:(NSDictionary *)data {
  return [self responseWithCode:FLTBResponseSuccess message:@"success" data:data];
}

+ (instancetype)notImplementResponseWithName:(NSString *)name {
  NSString *message = [NSString stringWithFormat:@"%@ not found", name];
  return [self responseWithCode:FLTBResponseNotFound message:message data:nil];
}

+ (instancetype)noPrivilegeResponseWithName:(NSString *)name {
  NSString *message = [NSString stringWithFormat:@"%@ no imple", name];
  return [self responseWithCode:FLTBResponseNoPrivilege message:message data:nil];
}

+ (instancetype)errorResponseWithMessage:(NSString *)message {
  return [self responseWithCode:FLTBResponseError message:message data:nil];
}

@end
