//
//  BDAutoTrackDevLogger.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackInspector,RangersLogObject;
@interface BDAutoTrackDevLogger : UIViewController

@property (nonatomic, weak) BDAutoTrackInspector *inspector;

@property (nonatomic, assign) BOOL autoRefresh;

@end

NS_ASSUME_NONNULL_END
