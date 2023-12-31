//
//  BDRLBaseCell.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDRLToolItem;

@interface BDRLBaseCell : UITableViewCell

- (void)configWithData:(BDRLToolItem *_Nullable)data;

@property (nonatomic, strong, readonly, nullable) BDRLToolItem *data;
@property (nonatomic, strong, nullable) UILabel *label;

@end

NS_ASSUME_NONNULL_END
