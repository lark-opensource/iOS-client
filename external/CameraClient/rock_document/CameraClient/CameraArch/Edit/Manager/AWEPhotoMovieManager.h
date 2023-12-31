//
//  AWETransitionTypeManager.h
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <TTVideoEditor/IESMMPhotoMovieDefine.h>

@protocol ACCMusicModelProtocol;
@class AWEVideoPublishViewModel;

@interface AWEPhotoMovieManager : NSObject

+ (NSInteger)audioRepeatCountForVideo:(AVAsset *)videoAsset
                           audioAsset:(AVAsset *)audioAsset;

@end
