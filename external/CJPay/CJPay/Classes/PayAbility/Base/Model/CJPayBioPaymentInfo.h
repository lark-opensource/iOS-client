//
//  CJPayBioPaymentInfo.h
//  CJPay
//
//  Created by 王新华 on 2019/3/31.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayBioPaymentSubGuideModel : JSONModel

@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *iconDesc;

@end


@protocol CJPayBioPaymentSubGuideModel;
@interface CJPayBioPaymentInfo : JSONModel

@property (nonatomic, assign) BOOL showGuide;
@property (nonatomic, copy) NSString *cancelBtnDesc;
@property (nonatomic, copy) NSString *openBioDesc;
@property (nonatomic, copy) NSString *guideDesc;
@property (nonatomic, copy) NSString *bioType;
@property (nonatomic, copy) NSString *successDesc;
@property (nonatomic, copy) NSString *showType;
@property (nonatomic, copy) NSArray<CJPayBioPaymentSubGuideModel> *subGuide;

@end

NS_ASSUME_NONNULL_END
