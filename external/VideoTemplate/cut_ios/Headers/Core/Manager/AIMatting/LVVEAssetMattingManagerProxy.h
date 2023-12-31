//
//  LVVEAssetMattingManagerProxy.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "LVAIMattingManager.h"

NS_ASSUME_NONNULL_BEGIN
@interface LVVEAssetMattingManagerProxy : NSObject<LVClipAIMattingProxy>

+ (instancetype)proxy;

@end

NS_ASSUME_NONNULL_END
