//
//  TTVideoEnginePortraitEngine.h
//  Pods
//
//  Created by bytedance on 2022/9/23.
//
#import <Foundation/Foundation.h>
#import "TTVideoEnginePortraitProtocol.h"

/**
 * 画像引擎
 */
@interface TTVideoEnginePortraitEngine : NSObject
@property(nonatomic, strong, nullable) NSMutableDictionary<NSString*, id> *labelMap;

- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)new NS_UNAVAILABLE;
+ (nonnull instancetype)instance;

- (void)setLabel:(nullable id)value withKey:(nullable NSString *)key;
- (nullable id)getLabel:(nullable NSString *)key;
- (nullable id)getEventData:(nullable NSString *)type;

@end
