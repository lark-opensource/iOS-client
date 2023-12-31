//
//  IESVideoDetectInputModelProtocol.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/5/26.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESVideoDetectInputModelProtocol <NSObject>

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVVideoComposition *videoComposition;
@property (nonatomic, strong) AVAudioMix *audioMix;
@property (nonatomic, copy) NSDictionary *extraLog;

@end

NS_ASSUME_NONNULL_END
