//
//  Stinger.h
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stinger/STDefines.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXTERN NSString *const StingerErrorDomain;

@interface NSObject (Stinger)

#pragma mark - For specific class

/// Adds a block of code before/instead/after the current `selector` for a specific class.
///
/// @param sel The method to be hooked.
/// @param options see `STOptions`
/// @param block The first parameter will be `id<StingerParams>`, followed by all parameters of the method.
/// @param error The error occured during hook, error code see `STHookErrorCode`
///
/// @return A token which allows to later remove the hook.
+ (nullable id<STToken>)st_hookInstanceMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error;
+ (nullable id<STToken>)st_hookClassMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error;

#pragma mark - For specific instance

/// Adds a block of code before/instead/after the current `selector` for a specific instance.
- (nullable id<STToken>)st_hookInstanceMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
