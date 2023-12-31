//
//  BDTuringTVViewController+Utility.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/8.
//

#import "BDTuringTVViewController+Utility.h"
#import "BDTuringIndicatorView.h"
#import "BDTuringPresentView.h"

@implementation BDTuringTVViewController (Utility)

- (void)dismissSelfControllerWithParams:(NSDictionary *)parmas error:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        __strong typeof(weakSelf) self = weakSelf;
        [[BDTuringPresentView defaultPresentView] hideTwiceVerifyViewController:self];
        if (self.callBack) {
            BDTuringTwiceVerifyResponse *response = [[BDTuringTwiceVerifyResponse alloc] init];
            response.type = self.blockType;
            response.params = parmas;
            response.error = error;
            self.callBack(response);
            self.callBack = nil;
        }
    }];
}

- (NSError *)createErrorWithErrorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg {
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : errorMsg };
    NSError *error = [NSError errorWithDomain:kBDTuringTVErrorDomain code:errorCode userInfo:userInfo];
    return error;
}

- (void)showLoading {
    [BDTuringIndicatorView showIndicatorForTextMessage:nil];
}

- (void)dismissLoading {
    [BDTuringIndicatorView dismissIndicators];
}


@end
