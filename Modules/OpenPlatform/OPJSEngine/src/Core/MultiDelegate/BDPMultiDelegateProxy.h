//
//  BDPMultiDelegateProxy.h
//  Timor
//
//  Created by dingruoshan on 2019/4/3.
//

#import <Foundation/Foundation.h>

/// 一对多的 delegate 类
@interface BDPMultiDelegateProxy : NSObject

/// silentWhenEmpty 用于控制当所有数组成员都没有实现某个方法时，调用时是否触发异常，设为YES时则不触发异常，设为NO时会触发异常，默认为NO，触发异常。
@property (nonatomic, assign) BOOL silentWhenEmpty;

- (instancetype _Nonnull)initWithDelegate:(id _Nullable)delegate;
- (instancetype _Nonnull)initWithDelegates:(NSArray * _Nullable)delegates;

- (NSUInteger)count;
- (NSArray *_Nonnull)allObjects;

- (void)addDelegate:(id _Nullable)delegate;
- (void)addDelegate:(id _Nullable)delegate beforeDelegate:(id _Nullable)otherDelegate;
- (void)addDelegate:(id _Nullable)delegate afterDelegate:(id _Nullable)otherDelegate;

- (void)removeDelegate:(id _Nullable)delegate;
- (void)removeAllDelegates;

@end
