//
//  DouyinOpenSDKAuthLicenseAgreement.h
//
//  Created by Spiker on 2020/1/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * _Nonnull const kDouyinLicenseAgreementAttrLinks;
FOUNDATION_EXTERN NSString * _Nonnull const kDouyinLicenseAgreementAttrItemLink;
FOUNDATION_EXTERN NSString * _Nonnull const kDouyinLicenseAgreementAttrItemRange;


@interface DouyinOpenSDKAuthLicenseAgreement :NSObject

@property(nonatomic, copy, nonnull) NSString *contentText;
@property(nonatomic, copy, nonnull) NSDictionary *attributes;

- (NSString *)quaryParamJson;

@end

NS_ASSUME_NONNULL_END
