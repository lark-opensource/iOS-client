//
//  BDASplashViewTargetActionProtocol.h
//  TTAdSplashSDK
//
//  Created by YangFani on 2020/8/17.
//

#import <Foundation/Foundation.h>
#import "BDASplashViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class TTAdSplashModel;

//#pragma clang diagnostic push
//#pragma clang diagnostic error "-Wprotocol"

@protocol BDASplashViewTargetActionProtocol <NSObject>

@property (nonatomic, weak) id<BDASplashViewProtocol> delegate;

@required

- (void)updateModel:(TTAdSplashModel *)model;

- (void)willAppear;

- (void)didDisappear;

- (void)willDisappear;

- (void)didAppear;

- (void)invalidPerform;

- (BOOL)haveClickAction;

- (void)skipAdWithSource:(NSString * _Nullable)source;

@end

//#pragma clang GCC pop

NS_ASSUME_NONNULL_END
