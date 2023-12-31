//
//  CJPayBridgeOCRModel.h
//  Pods
//
//  Created by 孔伊宁 on 2021/10/27.
//

#import <JSONModel/JSONModel.h>
#import "CJPayOCRFileResponseModel.h"
#import "CJPayOCRUploadResponseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOCRFileSourceModel : JSONModel

@property (nonatomic, copy) NSString *code;
@property (nonatomic, strong) CJPayOCRFileResponseModel *data;

@end

@interface CJPayOCRResponseModel : JSONModel

@property (nonatomic, copy) NSString *code;
@property (nonatomic, strong) CJPayOCRUploadResponseModel *data;

@end

NS_ASSUME_NONNULL_END
