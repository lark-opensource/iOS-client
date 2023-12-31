//
//  NLEEditor_OC+Extension.m
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import "NLEEditor_OC+Extension.h"

@implementation NLEEditor_OC (Extension)

- (void)acc_commitAndRender:(void (^)(NSError *_Nullable error))completion
{
    id<NLEEditorCommitContextProtocol> context = [self commit];
    [self doRender:context completion:^(NSError * _Nonnull renderError) {
        if ([NSThread isMainThread]) {
            !completion ?: completion(renderError);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                !completion ?: completion(renderError);
            });
        }
    }];
}

@end
