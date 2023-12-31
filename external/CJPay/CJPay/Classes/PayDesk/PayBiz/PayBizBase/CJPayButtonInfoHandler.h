//
//  CJPayButtonInfoHandler.h
//  CJPay-Example
//
//  Created by wangxinhua on 2020/9/20.
//

#import <Foundation/Foundation.h>
#import "CJPayIntergratedBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayButtonInfoHandlerActionModel: NSObject

@property (nonatomic, copy) void(^singleBtnAction)(NSInteger type);

@end


@interface CJPayButtonInfoHandler : NSObject

+ (BOOL)handleResponse:(CJPayIntergratedBaseResponse *)response fromVC:(UIViewController *)fromVC withActionsModel:(nonnull CJPayButtonInfoHandlerActionModel *)actionModel;

@end

NS_ASSUME_NONNULL_END
