//
// Created by 易培淮 on 2020/10/15.
//

#import <Foundation/Foundation.h>
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayQRCodeModel.h"

NS_ASSUME_NONNULL_BEGIN
@interface CJPayQRCodeViewController : CJPayHalfPageBaseViewController

@property (nonatomic, copy)   void(^queryResultBlock)(void(^completionBlock)(BOOL));
@property (nonatomic, copy)   void(^trackBlock)(void);
@property (nonatomic, copy)   void(^closeBlock)(void);
@property (nonatomic, assign) BOOL isNeedQueryResult;

- (instancetype) initWithModel:(CJPayQRCodeModel *)model;


@end
NS_ASSUME_NONNULL_END
