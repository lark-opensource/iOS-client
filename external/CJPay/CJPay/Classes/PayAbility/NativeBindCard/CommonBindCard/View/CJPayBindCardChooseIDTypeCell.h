//
//  CJPayBindCardChooseIDTypeCell.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import <UIKit/UIKit.h>
#import "CJPayBindCardCachedIdentityInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface  CJPayBindCardChooseIDTypeModel: NSObject

@property (nonatomic,copy) NSString *titleStr;
@property (nonatomic,assign) BOOL isSelected;
@property (nonatomic,assign) CJPayBindCardChooseIDType idType;

+ (NSString *)getIDTypeStr:(CJPayBindCardChooseIDType)idType;
+ (NSString *)getIDTypeWithCardTypeStr:(NSString *)cardType;

@end

@interface CJPayBindCardChooseIDTypeCell : UITableViewCell

- (void)updateWithModel:(CJPayBindCardChooseIDTypeModel *)model;

@end

NS_ASSUME_NONNULL_END
