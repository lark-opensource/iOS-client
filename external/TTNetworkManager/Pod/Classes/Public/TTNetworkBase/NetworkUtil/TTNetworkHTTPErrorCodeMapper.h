//
//  TTNetworkHTTPErrorCodeMapper.h
//  Pods
//
//  Created by Dai Dongpeng on 5/1/16.
//
//

#import <Foundation/Foundation.h>

@interface TTNetworkHTTPErrorCodeMapper : NSObject

/**
 *  Return the custom code corresponding to the error code
 *
 *  @param code  CFNetworkErrors type code
 *
 *  @return The corresponding custom code, if not found, 返回 NSNotFound
 */
+ (NSInteger)mapErrorCode:(NSInteger)code;

/**
 *  Return the custom code corresponding to errno
 *
 *  @param errorno Global error variable
 *
 *  @return Corresponding custom code, if not found, return NSNotFound
 */
+ (NSInteger)mapErrno:(NSInteger)errorno;

/**
 *  @return The custom code corresponding to kCFURLErrorUnknown: TTNetworkErrorCodeUnknown
 */
+ (NSInteger)unknonwErrorMapcode;

@end
