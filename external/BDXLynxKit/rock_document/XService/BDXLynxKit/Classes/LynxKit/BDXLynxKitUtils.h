//
//  BDXLynxKitUtils.h
//  BDXLynxKit
//
//  Created by tianbaideng on 2021/3/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxKitUtils : NSObject

+ (void)toastErrorMessage:(NSString *)message forDuration:(NSInteger)duration;
+ (BOOL)isRelativeURL:(NSURL *)url;
+ (BOOL)isResourceLoaderNotHandleURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
