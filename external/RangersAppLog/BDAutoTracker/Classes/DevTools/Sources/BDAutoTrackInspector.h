//
//  BDAutoTrackInspector.h
//  RangersAppLog
//
//  Created by bytedance on 6/28/22.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrack;
@interface BDAutoTrackInspector : UITabBarController

@property (nonatomic, weak, readonly) BDAutoTrack *currentTracker;

@end

NS_ASSUME_NONNULL_END
