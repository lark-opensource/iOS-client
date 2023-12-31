//
//  ACCStickerCompoundApplyHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/7/27.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"

NS_ASSUME_NONNULL_BEGIN


@protocol ACCStickerCompoundHandler <NSObject>

+ (instancetype)compoundHandler;
- (void)addHandler:(ACCStickerHandler *)handler;

@end

@interface ACCStickerCompoundHandler : ACCStickerHandler <ACCStickerCompoundHandler>

@property (nonatomic, strong, readonly) NSArray<ACCStickerHandler *> *handlers;

@end


NS_ASSUME_NONNULL_END
