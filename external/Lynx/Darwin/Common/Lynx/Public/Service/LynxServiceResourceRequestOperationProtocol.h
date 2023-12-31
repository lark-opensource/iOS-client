//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEREQUESTOPERATIONPROTOCOL_H_
#define DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEREQUESTOPERATIONPROTOCOL_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LynxServiceResourceRequestOperationProtocol <NSObject>

@property(nonatomic, copy) NSString* _Nullable url;

- (BOOL)cancel;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_SERVICE_LYNXSERVICERESOURCEREQUESTOPERATIONPROTOCOL_H_
