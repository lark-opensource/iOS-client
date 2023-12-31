//
//  BDLynxProvider.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/2/21.
//

#import <Foundation/Foundation.h>
#import "LynxTemplateProvider.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDLynxProviderDelegate <NSObject>

- (void)bdlynxViewloadTemplateWithUrl:(NSString*)url onComplete:(LynxTemplateLoadBlock)callback;

@end

@interface BDLynxProvider : NSObject <LynxTemplateProvider>

@property(nonatomic, weak) id<BDLynxProviderDelegate> lynxProviderDelegate;

@end

NS_ASSUME_NONNULL_END
