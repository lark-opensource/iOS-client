// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCEREQUEST_H_
#define DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCEREQUEST_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxResourceRequest : NSObject

@property(nonatomic, readonly, copy) NSString* url;
@property(nonatomic, readonly, strong) id requestParams;

- (instancetype)initWithUrl:(NSString*)url;
- (instancetype)initWithUrl:(NSString*)url andRequestParams:(id)requestParams;

@end

NS_ASSUME_NONNULL_END

#endif  // DARWIN_COMMON_LYNX_RESOURCE_LYNXRESOURCEREQUEST_H_
