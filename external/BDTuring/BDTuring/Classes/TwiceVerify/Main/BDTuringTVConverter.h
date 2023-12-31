//
//  BDTuringTVConverter.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/30.
//

#import <Foundation/Foundation.h>
#import "BDTuringTVDefine.h"
#import "BDTuringTwiceVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN BDTuringTwiceVerifyModel *turing_tvRequestToModel(BDTuringTwiceVerifyRequest *request);
FOUNDATION_EXTERN BDTuringTwiceVerifyRequest *turing_tvModelToRequest(BDTuringTwiceVerifyModel *model);
FOUNDATION_EXTERN BDTuringVerifyResult *turing_tvReponseToResult(BDTuringTwiceVerifyResponse *response);

NS_ASSUME_NONNULL_END
