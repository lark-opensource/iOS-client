//
//  CJPayHandleErrorResponseModel.h
//  Pods
//
//  Created by 孔伊宁 on 2022/2/23.
//

#import <Foundation/Foundation.h>
#import "CJPayErrorButtonInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayHandleErrorResponseModel : NSObject

@property (nonatomic, copy) NSString *code;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
