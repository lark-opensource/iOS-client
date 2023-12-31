//
//  BDCTVideoRecordPreviewViewController.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import <UIKit/UIKit.h>

@class BDCTVideoRecordPreviewViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol BDCTVideoRecordPreviewViewControllerDelegate <NSObject>

- (void)videoRecordPreviewViewControllerDidTapRerecordVideo:(BDCTVideoRecordPreviewViewController *)viewController;
- (void)videoRecordPreviewViewControllerDidTapUploadVideo:(BDCTVideoRecordPreviewViewController *)viewController videoPathURL:(NSURL *)videoPathURL;

@end


@interface BDCTVideoRecordPreviewViewController : UIViewController

@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, weak) id<BDCTVideoRecordPreviewViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
