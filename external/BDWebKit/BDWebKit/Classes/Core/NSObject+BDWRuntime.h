//
//  NSObject+BDWRuntime.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (BDWRuntime)

- (void)bdw_attachObject:(nullable id)obj forKey:(NSString *)key;
- (nullable id)bdw_getAttachedObjectForKey:(NSString *)key;

- (void)bdw_attachObject:(nullable id)obj forKey:(NSString *)key isWeak:(BOOL)bWeak;
- (nullable id)bdw_getAttachedObjectForKey:(NSString *)key isWeak:(BOOL)bWeak;

@end

NS_ASSUME_NONNULL_END
