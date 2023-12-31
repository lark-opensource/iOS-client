//
//  BDAutoTrackLoggerCell.h
//  RangersAppLog
//
//  Created by bytedance on 7/4/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RangersLogObject;
@interface BDAutoTrackLoggerCell : UITableViewCell

@property (nonatomic, strong) RangersLogObject* log;

- (void)update;

+ (CGFloat)estimateHeight:(RangersLogObject *)log;

@end

NS_ASSUME_NONNULL_END
