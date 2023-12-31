//
//  NLEContextProcessor+iOS.h
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NLEContextProcessorDelegate<NSObject>

- (NSString *)encryptWithContext:(NSString *)context;
- (NSString *)decryptWithContextPath:(NSString *)contextPath;

@end

@interface NLEContextProcessor_OC : NSObject

+ (NSString *)encryptWithContext:(NSString *)context;
+ (NSString *)decryptWithContextPath:(NSString *)contextPath;

+ (void)registerDelegate:(id<NLEContextProcessorDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
