//
//  BDLynxProvider.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/2/21.
//

#import "BDLynxProvider.h"

@implementation BDLynxProvider

- (void)loadTemplateWithUrl:(NSString*)url onComplete:(LynxTemplateLoadBlock)callback {
  [self.lynxProviderDelegate bdlynxViewloadTemplateWithUrl:url onComplete:callback];
}

@end
