//
//  CJPayRetainRecommendInfoModel.h
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import <UIKit/UIKit.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayRetainRecommendInfoModel : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *topRetainButtonText;
@property (nonatomic, copy) NSString *bottomRetainButtonText;

@end

NS_ASSUME_NONNULL_END
