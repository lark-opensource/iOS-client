// Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxResourceServiceFetcher.h"

#import "LynxError.h"
#import "LynxService.h"
#import "LynxServiceResourceProtocol.h"

@implementation LynxResourceServiceFetcher

+ (id<LynxServiceResourceProtocol>)getLynxService {
  return LynxService(LynxServiceResourceProtocol);
}

+ (BOOL)ensureLynxService {
  return [LynxResourceServiceFetcher getLynxService] != nil;
}

// required interface, recommend to use loadResourceWithURLString directly
- (dispatch_block_t)loadResourceWithURL:(NSURL *)url
                                   type:(LynxFetchResType)type
                             completion:(LynxResourceLoadCompletionBlock)completionBlock {
  [self loadResourceWithURLString:[url relativePath] completion:completionBlock];
  return nil;
}

/*
 * send resource request with completion block
 * Notice: The isSyncCallback parameter of completionBlock does not truly reflect whether the
 * request is sync or not.
 * Do not rely on it !!!
 */
- (void)loadResourceWithURLString:(NSString *)urlString
                       completion:(LynxResourceLoadCompletionBlock)completionBlock {
  id<LynxServiceResourceProtocol> service = [LynxResourceServiceFetcher getLynxService];
  if (service != nil) {
    // Network requests should not be made on the main thread, so async method of forest are always
    // called
    id<LynxServiceResourceRequestOperationProtocol> operation = [service
        fetchResourceAsync:urlString
                parameters:[LynxServiceResourceRequestParameters new]
                completion:^(id<LynxServiceResourceResponseProtocol> _Nullable response,
                             NSError *_Nullable error) {
                  if (response == nil && error == nil) {
                    error = [LynxError lynxErrorWithCode:LynxErrorCodeExternalSource
                                             description:@"Lynx resource service response is nil"];
                  }
                  completionBlock(false, error ? nil : [response data], error, nil);
                }];
    if (operation == nil) {
      completionBlock(true, nil,
                      [LynxError lynxErrorWithCode:LynxErrorCodeExternalSource
                                       description:@"Lynx resource service operation is nil"],
                      nil);
      return;
    }
  } else {
    completionBlock(true, nil,
                    [LynxError lynxErrorWithCode:LynxErrorCodeExternalSource
                                     description:@"Lynx resource service init fail"],
                    nil);
  }
}

@end
