//
//  BDRLSwitchCell.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import "BDRLBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@class BDRLSwitchCell;

@protocol BDRLToolSwitchCellDelegate <NSObject>
@optional
- (void)handleSwitchChange:(BOOL)isOn itemTitle:(NSString *_Nullable)itemTitle;
- (void)handleCellSwitchChange:(BDRLSwitchCell *_Nullable)cell;
@end

@interface BDRLSwitchCell : BDRLBaseCell
@property (nonatomic, weak, nullable) id<BDRLToolSwitchCellDelegate> delegate;
@property (nonatomic, copy, nullable) NSString *scene;
@property (nonatomic, strong, nullable) UISwitch *switchCtrl;
@end

NS_ASSUME_NONNULL_END
