//
//  OpusConfig.h
//  OCOpusCodec
//
//  Created by 李晨 on 2019/3/11.
//  Copyright © 2019 lichen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OpusConfig : NSObject

+ (nonnull instancetype)sharedInstance;

// 一帧s数据最大值 默认为 5760
@property (nonatomic, assign) int maxFrameSize;

// 每一个 ogg page 包含的音频帧数 默认为 50
@property (nonatomic, assign) int frameCountPerOggPage;

// 每一个音频帧的时长 默认为 0.02s
@property (nonatomic, assign) float frameDuration;

// 采样频率 默认为 16000
@property (nonatomic, assign) int sampleRate;

// 声道数 默认为 1
@property (nonatomic, assign) int channelCount;

// 采样位数 默认为 16
@property (nonatomic, assign) int bitPerSample;

@end
