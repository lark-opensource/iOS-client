//
//  BDAutoTrackDevEnv.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrackInspector;
@interface BDAutoTrackDevEnv : UIViewController

@property (nonatomic, weak) BDAutoTrackInspector *inspector;

- (NSString *)dump;

@end

NS_ASSUME_NONNULL_END
