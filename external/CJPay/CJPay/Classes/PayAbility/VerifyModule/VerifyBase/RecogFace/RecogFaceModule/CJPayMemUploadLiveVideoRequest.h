//
//  CJPayMemUploadLiveVideoRequest.h
//  CJPaySandBox
//
//  Created by 尚怀军 on 2022/11/21.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBaseResponse;
@interface CJPayMemUploadLiveVideoRequest : CJPayBaseRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
              bizContentParams:(NSDictionary *)bizContentParams
                    completion:(void (^)(NSError * _Nonnull, CJPayBaseResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
