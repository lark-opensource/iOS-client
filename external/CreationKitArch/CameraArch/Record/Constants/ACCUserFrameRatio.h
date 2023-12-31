//
//  ACCUserFrameRatio.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/9/1.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, ACCUserFrameRatio) {
    ACCUserFrameRatioH16V9 = 0,
    ACCUserFrameRatioH1V1 = 1,
    ACCUserFrameRatioH9V16 = 2,
    ACCUserFrameRatioMaxValue = ACCUserFrameRatioH9V16
};

typedef NS_ENUM (NSUInteger, ACCExportRatio) {
    ACCExportRatioH9V16 = 0, // Over the proportion of full screen 
    ACCExportRatioH1V1 = 1,
    ACCExportRatioH16V9 = 2,
};

NS_ASSUME_NONNULL_BEGIN

static inline NSString * ACCUserFrameRatioTrackerType(ACCUserFrameRatio ratio)
{
    switch (ratio) {
        case ACCUserFrameRatioH9V16:
            return @"9-16";
        case ACCUserFrameRatioH1V1:
            return @"1-1";
        case ACCUserFrameRatioH16V9:
            return @"16-9";
    }
}

NS_ASSUME_NONNULL_END
