//
//  CJPayFEGuideInfoModel.h
//  Pods
//
//  Created by 尚怀军 on 2021/12/29.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFEGuideInfoModel : JSONModel

@property (nonatomic, copy) NSString *guideType;
@property (nonatomic, copy) NSString *url;
@end

NS_ASSUME_NONNULL_END
