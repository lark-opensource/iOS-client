//
//  CJPayProcessInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface CJPayProcessInfo : JSONModel

@property (nonatomic,copy)NSString *createTime;
@property (nonatomic,copy)NSString *processId;
@property (nonatomic,copy)NSString *processInfo;

- (BOOL)isValid;
- (NSDictionary *)dictionaryValue;

@end
