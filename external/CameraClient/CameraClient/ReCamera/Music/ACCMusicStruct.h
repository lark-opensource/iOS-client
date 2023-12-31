//
//  ACCMusicStruct.h
//  CameraClient
//
//  Created by Liu Deping on 2020/1/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicStruct <NSObject>

@property (nonatomic, strong) NSURL *cachedURL;
@property (nonatomic, assign) NSTimeInterval musicStartTime;
@property (nonatomic, assign) NSTimeInterval videoMaxSeconds;
@property (nonatomic, assign) NSTimeInterval musicClipLength;

@end

NS_ASSUME_NONNULL_END
