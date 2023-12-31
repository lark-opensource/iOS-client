//
//  BDAutoTrackSummary.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrackFormGroup;
@interface BDAutoTrackSummary : UIViewController

@property (nonatomic, strong) NSArray<BDAutoTrackFormGroup *> *groups;

@end

NS_ASSUME_NONNULL_END
