//
//  CJPayBackBlockModel.h
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJBackBlockActionModel : JSONModel
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger action;
@property (nonatomic, copy) NSString *fontWeight;

@end

@interface CJPayBackBlockModel : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, assign) NSInteger policy;

@property (nonatomic, strong) CJBackBlockActionModel *confirmModel;
@property (nonatomic, strong) CJBackBlockActionModel *cancelModel;

@end

NS_ASSUME_NONNULL_END
