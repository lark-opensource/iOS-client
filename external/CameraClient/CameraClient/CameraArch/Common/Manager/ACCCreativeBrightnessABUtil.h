//
//  ACCCreativeBrightnessABUtil.h
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2021/3/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCreativeBrightnessABUtil : NSObject

@property (nonatomic, strong, readonly) NSNumber *currentBrightness;

+ (instancetype)shareBrightnessManager;

- (void)adjustBrightnessWhenEnterCreationLine;

- (void)resumeBrightnessWhenEnterEditor;

- (void)resumeBrightnessWhenEnterPublish;

- (void)restoreBrightness;

@end

NS_ASSUME_NONNULL_END
