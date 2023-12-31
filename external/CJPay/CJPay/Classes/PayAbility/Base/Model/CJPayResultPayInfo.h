//
//  CJPayResultPayInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/27.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface CJPayResultPayInfo : JSONModel

@property (nonatomic, copy) NSString *typeMark;
@property (nonatomic, copy) NSString *amount;
@property (nonatomic, copy) NSString *payType;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *halfScreenDesc;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *colorType;
@property (nonatomic, copy) NSString *payTypeShowName;

@end
