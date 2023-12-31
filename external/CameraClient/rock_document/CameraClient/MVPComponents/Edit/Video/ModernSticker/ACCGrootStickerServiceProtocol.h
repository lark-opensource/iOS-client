//
//  ACCGrootStickerServiceProtocol.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/5/21.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

@protocol ACCGrootStickerServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *showGrootStickerTipsSignal;
@property (nonatomic, strong, readonly) RACSignal<NSString *> *sendAutoAddGrootHashtagSignal;

@end
