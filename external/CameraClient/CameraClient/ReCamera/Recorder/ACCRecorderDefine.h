//
//  ACCRecorderDefine.h
//  Pods
//
//  Created by 郝一鹏 on 2019/12/26.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/IESMMCaptureOptions.h>

typedef NS_ENUM(NSUInteger, ACCRecorderMode) {
    ACCRecorderModeVideo,
    ACCRecorderModePhoto,
};

typedef NS_ENUM(NSUInteger, ACCRecorderStatus) {
    ACCRecorderStatusReady,
    ACCRecorderStatusRunning,
    ACCRecorderStatusPending
};

@interface ACCRecorderConfig : NSObject

@property (nonatomic, nullable) NSNumber *videoRate;
@property (nonatomic, nullable) IESMMCaptureOptions *photoOptions;

@end
