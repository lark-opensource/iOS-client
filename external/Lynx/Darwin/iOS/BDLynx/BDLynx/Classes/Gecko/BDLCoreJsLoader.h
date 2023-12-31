//
//  BDLCoreJsLoader.h
//  Pods
//
//  Created by admin on 2020/8/31.
//

#import <Foundation/Foundation.h>
#import "CoreJsLoaderManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLCoreJsLoader : NSObject <ICoreJsLoader>
- (instancetype)initWithOnline:(bool)isOnline;
@end

NS_ASSUME_NONNULL_END
