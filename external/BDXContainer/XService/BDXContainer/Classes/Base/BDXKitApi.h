//
// Created by duanefaith on 2019/10/12.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXKitViewProtocol;
@class BDXContext;

@interface BDXKitApi : NSObject

@property(nonatomic, weak) BDXContext *context;

- (instancetype)initWithContext:(BDXContext *)context;

- (nullable UIView<BDXKitViewProtocol> *)provideKitViewWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
