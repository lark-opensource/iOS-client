//
//  CJPaySwitchAreaInfoModel.h
//  Pods
//
//  Created by 孔伊宁 on 2022/1/14.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySwitchAreaInfoModel : JSONModel

@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *bioType;
@property (nonatomic, copy) NSString *downgradeReason;

@end

NS_ASSUME_NONNULL_END
