//
//  BDTuringTVConverter.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/30.
//

#import "BDTuringTVConverter.h"
#import "BDTuringPresentView.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringVerifyResult.h"

/// why need this?
BDTuringTwiceVerifyModel *turing_tvRequestToModel(BDTuringTwiceVerifyRequest *request) {
    BDTuringTwiceVerifyModel *model = [BDTuringTwiceVerifyModel new];
    model.params = request.params;
    return model;
}

/// why need this?
BDTuringTwiceVerifyRequest *turing_tvModelToRequest(BDTuringTwiceVerifyModel *model) {
    BDTuringTwiceVerifyRequest *request = [BDTuringTwiceVerifyRequest new];
    request.params = model.params;
    request.superVC = [BDTuringPresentView defaultPresentView].rootViewController;
    return request;
}

/// why need this?
BDTuringVerifyResult *turing_tvReponseToResult(BDTuringTwiceVerifyResponse *response) {
    if (response == nil || ![response.params isKindOfClass:[NSDictionary class]]) {
        return [BDTuringVerifyResult unsupportResult];
    }
    NSUInteger code = [response.params turing_integerValueForKey:@"status_code"];
    switch (code) {
        case 0:
            return [BDTuringVerifyResult okResult];
            break;
        case 1:
            return [BDTuringVerifyResult failResult];
            break;
        default:
            return [BDTuringVerifyResult failResult];
            break;
    }
}
