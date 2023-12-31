//
//  CJPayCustomSettings.h
//  CJPay
//
//  Created by 王新华 on 10/21/19.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface CJPayCustomSettings : JSONModel

@property (nonatomic, copy) NSString *withdrawPageTitle;
@property (nonatomic, copy) NSString *withdrawPageMiddleText;
@property (nonatomic, copy) NSString *withdrawPageBottomText;
@property (nonatomic, copy) NSDictionary *withdrawResultPageDescDict;
@property (nonatomic, copy) NSDictionary *withdrawPageMiddleTextDict;

@end

NS_ASSUME_NONNULL_END
