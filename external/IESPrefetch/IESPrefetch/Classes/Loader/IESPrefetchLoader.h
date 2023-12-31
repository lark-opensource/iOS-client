//
//  IESPrefetchLoader.h
//  IESPrefetch
//
//  Created by Hao Wang on 2019/6/28.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchDefines.h"
#import "IESPrefetchLoaderPrivateProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IESPrefetchLoaderPrivateProtocol;

@interface IESPrefetchLoader : NSObject<IESPrefetchLoaderPrivateProtocol>

- (instancetype)initWithCapability:(id<IESPrefetchCapability>)capability business:(NSString *)business;

@end

NS_ASSUME_NONNULL_END
