//
//  BDRLParameterCell.h
//  BDRuleEngine
//
//  Created by WangKun on 2021/12/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDRuleParameterBuilderModel;

@protocol BDRLToolParameterDelegate <NSObject>

- (void)handleParameterValueChanged:(BDRuleParameterBuilderModel *)parameter value:(NSString *)value;

@end

@interface BDRLParameterCell : UITableViewCell

@property (nonatomic, weak) id<BDRLToolParameterDelegate> delegate;
@property (nonatomic, strong, readonly, nullable) BDRuleParameterBuilderModel *data;

- (void)configWithData:(BDRuleParameterBuilderModel *_Nullable)data;

@end

NS_ASSUME_NONNULL_END
