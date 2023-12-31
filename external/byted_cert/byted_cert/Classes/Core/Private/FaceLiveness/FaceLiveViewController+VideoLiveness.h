//
//  FaceLiveViewController+VideoLiveness.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/16.
//

#import "FaceLiveViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertVideoLivenessReadNumberView : UILabel

- (void)updateNumber:(NSString *_Nullable)number maxLength:(int)maxLength;

- (void)clear;

@end


@interface FaceLiveViewController (VideoLiveness)

@property (nonatomic, strong, readonly) BytedCertVideoLivenessReadNumberView *readNumberView;

- (void)doUpload:(NSString *)videoPath resultCode:(int)code;

- (void)showReuploadAlert:(NSString *)path code:(int)code actionCompletion:(nullable void (^)(NSString *))actionCompletion;

@end

NS_ASSUME_NONNULL_END
