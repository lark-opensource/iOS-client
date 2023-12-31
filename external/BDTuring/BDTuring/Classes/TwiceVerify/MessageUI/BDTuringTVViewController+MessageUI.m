//
//  BDTuringTVViewController+CN.m
//  BDTuring
//
//  Created by ccc on 2021/5/25.
//

#import "BDTuringTVViewController+MessageUI.h"
#import "BDTuringPiperConstant.h"

@implementation BDTuringTVViewController (MessageUI)

- (void)presentMessageComposeViewControllerWithPhone:(NSString *)phone content:(NSString *)content {
    MFMessageComposeViewController *vc = [[MFMessageComposeViewController alloc]init];
    vc.body = content;
    vc.recipients = @[phone];
    vc.messageComposeDelegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - delegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
    BDTuringPiperMsg value = result == MessageComposeResultSent  ? BDTuringPiperMsgSuccess : BDTuringPiperMsgFailed;
    BDTuringPiperOnCallback cacheCallback = self.cacheCallback;
    if (cacheCallback) {
        cacheCallback(value, nil);
        self.cacheCallback = nil;
    }
}

+ (BOOL)canSendText {
    return  [MFMessageComposeViewController canSendText];
}

@end
