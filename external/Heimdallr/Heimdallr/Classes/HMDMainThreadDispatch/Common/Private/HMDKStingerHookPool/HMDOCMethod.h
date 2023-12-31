//
//  HMDOCMethod.h
//  Heimdallr
//
//  Created by bytedance on 2022/10/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDOCMethod : NSObject

@property(nonatomic, readonly, getter=isClassMethod) BOOL classMethod;

@property(nonatomic, readonly, nonnull) Class methodClass;

@property(nonatomic, readonly, nonnull) SEL selector;

@property(atomic, assign) NSUInteger status;

- (instancetype _Nullable)initWithClass:(Class _Nonnull)aClass
                               selector:(SEL)selector
                            classMethod:(BOOL)classMethod NS_DESIGNATED_INITIALIZER;

- (instancetype _Nullable)initWithString:(NSString * _Nonnull)methodString;

+ (instancetype _Nullable)methodWithString:(NSString * _Nonnull)methodString;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Equal and Hash

- (BOOL)isEqual:(id _Nonnull)object;

- (BOOL)isEqualToMethod:(HMDOCMethod * _Nonnull)method;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
