//
//  MaterialAnimationUtilsHelper.h
//  VideoTemplate
//
//  Created by Lemonior on 2020/4/23.
//

#import <Foundation/Foundation.h>

@class LVDraftAnimationPayload;

@interface MaterialAnimationUtilsHelper : NSObject

+ (BOOL)isLoop:(LVDraftAnimationPayload *)animationPayload;
+ (NSString *)getInAnimPath:(LVDraftAnimationPayload *)animationPayload;
+ (NSString *)getOutAnimPath:(LVDraftAnimationPayload *)animationPayload;
+ (NSString *)getLoopAnimPath:(LVDraftAnimationPayload *)animationPayload;
+ (uint64_t)getInAnimDuration:(LVDraftAnimationPayload *)animationPayload;
+ (uint64_t)getOutAnimDuration:(LVDraftAnimationPayload *)animationPayload;
+ (uint64_t)getLoopAnimDuration:(LVDraftAnimationPayload *)animationPayload;

@end
