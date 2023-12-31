//
//  CJPaySeparateTextFieldConfigration.h
//  CJPay
//
//  Created by 王新华 on 4/12/20.
//

#import "CJPayCustomTextFieldConfigration.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySeparateTextFieldConfigration : CJPayCustomTextFieldConfigration

@property (nonatomic,assign) NSInteger separateCount;
@property (nonatomic,copy) NSArray *separateArray;
@property (nonatomic,assign) NSInteger limitCount;
@property (nonatomic,strong) NSCharacterSet *supportCharacterSet;
@property (nonatomic,assign) BOOL disableSeparate;

@end

NS_ASSUME_NONNULL_END
