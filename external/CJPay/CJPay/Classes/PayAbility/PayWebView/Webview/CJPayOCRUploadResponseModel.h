//
//  CJPayOCRUploadResponseModel.h
//  Pods
//
//  Created by bytedance on 2021/11/3.
//

#import <JSONModel/JSONModel.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayOCRUploadResponseModel : JSONModel

@property (nonatomic, assign) NSInteger httpCode;
@property (nonatomic, copy) NSDictionary *header;
@property (nonatomic, copy) NSString *response;

@end

NS_ASSUME_NONNULL_END
