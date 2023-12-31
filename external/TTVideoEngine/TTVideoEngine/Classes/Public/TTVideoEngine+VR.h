//
//  TTVideoEngine+VR.h
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngine.h"
#import "TTVideoEngineVRReaction.h"
#import "TTVideoEngineVRModel.h"

NS_ASSUME_NONNULL_BEGIN

//@interface TTVideoEngine() <TTVideoEngineVRReaction>
//
//@end

@interface TTVideoEngine (VR) <TTVideoEngineVRReaction>

- (void)setVREffectParamter:(NSDictionary *)paramter;

@end

NS_ASSUME_NONNULL_END
