//
//  TTVideoEngineVRReaction.h
//  TTVideoEngine
//
//  Created by shen chen on 2022/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEngineVRReaction <NSObject>

- (void)setEffectParams:(NSDictionary *)params;

- (void)setIntOptionValue:(NSInteger)value forKey:(NSInteger)key;

@end
NS_ASSUME_NONNULL_END
