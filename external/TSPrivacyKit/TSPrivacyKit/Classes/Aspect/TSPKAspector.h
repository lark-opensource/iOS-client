//
//  TSPKAspector.h
//  TestMe
//
//  Created by bytedance on 2021/12/4.
//

#import <Foundation/Foundation.h>

@interface TSPKAspector : NSObject
//you can create you own instance, without using singleton by default
- (instancetype _Nullable)initWithEntry:(IMP _Nullable)onEntry Exit:(IMP _Nullable)onExit;
- (BOOL)swizzleInstanceMethod:(Class _Nullable)cls Method:(SEL _Nullable)origSelector ReturnStruct:(BOOL)returnsAStructValue;
- (BOOL)swizzleClassMethod:(Class _Nullable)cls Method:(SEL _Nullable)origSelector ReturnStruct:(BOOL)returnsAStructValue;

//singleton by default
+ (void)setOnEntry:(IMP _Nullable)entryFunc;
+ (void)setOnExit:(IMP _Nullable)exitFunc;
+ (BOOL)swizzleInstanceMethod:(Class _Nullable)cls Method:(SEL _Nullable)origSelector ReturnStruct:(BOOL)returnsAStructValue;
+ (BOOL)swizzleClassMethod:(Class _Nullable)cls Method:(SEL _Nullable)origSelector ReturnStruct:(BOOL)returnsAStructValue;
@end

