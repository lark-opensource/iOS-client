//
//  BDAutoTrackDevEventCell.h
//  RangersAppLog
//
//  Created by bytedance on 2022/10/27.
//

#import <UIKit/UIKit.h>
#import "BDAutoTrackDevEventData.h"

@interface BDAutoTrackDevEventCell : UITableViewCell

@property (nonatomic, strong) BDAutoTrackDevEventData* event;

- (void)update;

+ (CGFloat)estimateHeight:(BDAutoTrackDevEventData *) event;

@end
