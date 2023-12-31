//
//  ACCRecognitionGrootConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/23.
//

#import <Foundation/Foundation.h>

#define RECOGNITION_GROOT_TAG 0x7ec09970

@interface ACCRecognitionGrootConfig : NSObject

+ (BOOL)enabled;

+ (NSInteger)stickerStyle;

+ (NSString *)grootStickerId;

@end
