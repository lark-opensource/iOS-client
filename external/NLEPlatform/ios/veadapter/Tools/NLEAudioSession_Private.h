//
//  NLEAudioSession_Private.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/4/26.
//

#import "NLEAudioSession.h"
#import "NLEMacros.h"

@class HTSVideoData;
typedef void(^NLECommitBlock)(HTSVideoData *videoData);

@interface NLEAudioSession ()

- (instancetype)initWithVideoData:(HTSVideoData *)videoData;

@property (nonatomic, copy) void(^commitBlock)(NLECommitBlock completion);

@end
