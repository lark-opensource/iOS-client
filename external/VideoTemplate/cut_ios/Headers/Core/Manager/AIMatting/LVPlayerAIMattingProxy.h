//
//  LVPlayerItemAiMattingProxy.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/11/30.
//

#import <Foundation/Foundation.h>
#import "LVAIMattingManager.h"
NS_ASSUME_NONNULL_BEGIN

@class LVPlayer;
@interface LVPlayerAIMattingProxy : NSObject<LVClipAIMattingProxy>
+ (instancetype)proxyWithPlayer:(LVPlayer *)adapter;
@end

@interface LVAIMattingManager (LVPlayer)

+ (instancetype)managerWithPlayer:(LVPlayer *)adapter;

@end


NS_ASSUME_NONNULL_END
