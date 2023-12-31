//
//  BDAutoTrackDropDownLabel.h
//  RangersAppLog
//
//  Created by bytedance on 7/4/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDAutoTrackDropDownDelegate <NSObject>

- (NSUInteger)numbersOfdropDownItems:(id)label;

- (NSString *)dropDownLabel:(id)label selectedIndex:(NSUInteger)index;

- (void)dropDownLabelDidUpdate:(id)label;

@end

@interface BDAutoTrackDropDownLabel : UIView

@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, weak) id delegate;

@end

NS_ASSUME_NONNULL_END
