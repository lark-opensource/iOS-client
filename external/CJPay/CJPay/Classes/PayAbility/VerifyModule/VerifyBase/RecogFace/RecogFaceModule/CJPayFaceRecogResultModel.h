//
//  CJPayFaceRecogResultModel.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 活体验证结果
typedef NS_ENUM(NSUInteger, CJPayFaceRecogResultType) {
    CJPayFaceRecogResultTypeSuccess,      // 活体验证成功
    CJPayFaceRecogResultTypeFail,         // 活体验证失败
    CJPayFaceRecogResultTypeCancel,       // 活体验证取消
};

@class CJPayGetTicketResponse;
@interface CJPayFaceRecogResultModel : NSObject

@property (nonatomic, assign) CJPayFaceRecogResultType result;
@property (nonatomic, copy, nullable) NSString *faceDataStr;
@property (nonatomic, strong, nullable) CJPayGetTicketResponse *getTicketResponse;

@end

NS_ASSUME_NONNULL_END
