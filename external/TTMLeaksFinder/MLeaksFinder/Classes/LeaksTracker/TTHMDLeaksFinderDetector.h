//
//  HMDTTLeaksFinderDetector.h
//  Heimdallr_Example
//
//  Created by bytedance on 2020/5/29.
//  Copyright © 2020 ghlsb@hotmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TTHMDLeaksFinderDetector, TTHMDLeaksFinderRecord;

NS_ASSUME_NONNULL_BEGIN

@protocol TTHMDLeaksFinderDetectorDelegate <NSObject>

- (void)detector:(TTHMDLeaksFinderDetector *)detector didDetectData:(TTHMDLeaksFinderRecord *)data;

@end

@interface TTHMDLeaksFinderDetector : NSObject

@property (nonatomic, weak) id<TTHMDLeaksFinderDetectorDelegate> delegate;

+ (instancetype)shareInstance;

- (void)start;
- (void)stop;

- (void)updateConfig:(id)config;

@end

NS_ASSUME_NONNULL_END
