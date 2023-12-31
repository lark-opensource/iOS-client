//
//  CJPayMemAuthInfo.h
//  BDPay
//
//  Created by 易培淮 on 2020/6/4.
//


#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemAuthInfo : JSONModel

@property(nonatomic, copy) NSString *payUID;
@property(nonatomic, assign) NSInteger memberLevel;

@property(nonatomic, assign) NSInteger memberType;
@property(nonatomic, assign) BOOL isSetPWD;
@property(nonatomic, assign) BOOL isAuthed;
@property(nonatomic, assign) BOOL isOpenAccount;
@property(nonatomic, copy) NSString *customerID;
@property(nonatomic, copy) NSString *mobileMask;
@property(nonatomic, copy) NSString *contactAddress;
@property(nonatomic, copy) NSString *country;
@property(nonatomic, copy) NSString *countryName;
@property(nonatomic, copy) NSString *idCodeMask;
@property(nonatomic, copy) NSString *idExpireDate;
@property(nonatomic, copy) NSString *idNameMask;
@property(nonatomic, copy) NSString *idPhotoStatus;
@property(nonatomic, copy) NSString *idType;
@property(nonatomic, assign) BOOL isIdPhotoUploaded;
@property(nonatomic, copy) NSString *identityCodeMask;
@property(nonatomic, copy) NSString *job;
@property(nonatomic, copy) NSString *sex;
@property(nonatomic, copy) NSString *sexName;

@end

NS_ASSUME_NONNULL_END
