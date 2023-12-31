//
//  NLEAllKeyFrameInfo.h
//  NLEPlatform
//
//  Created by bytedance on 2021/8/30.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEAllKeyFrameInfo : NSObject

@property (nonatomic, strong, nullable) NSMutableDictionary<AVAsset *, NSString *> *canvasKeyFrames;

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSString *> *featureKeyFrames;
 
@property (nonatomic, strong, nullable) NSMutableDictionary<NSNumber *, NSString *> *infoStickerKeyFrames;


@end

NS_ASSUME_NONNULL_END
