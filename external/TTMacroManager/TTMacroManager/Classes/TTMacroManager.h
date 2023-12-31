//
//  TTMacroManager.h
//  TTMacroManager
//
//  Created by Bob on 2018/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTMacroManager : NSObject

+ (BOOL)isDebug;
+ (BOOL)isRelease;
+ (BOOL)isInHouse;
+ (BOOL)isAddressSanitizer;
+ (BOOL)isThreadSanitizer;

@end

NS_ASSUME_NONNULL_END
