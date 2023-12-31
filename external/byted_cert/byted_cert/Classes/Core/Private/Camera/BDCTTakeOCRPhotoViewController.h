//
//  BDCTManualReviewViewController.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/3/15.
//

#import <UIKit/UIKit.h>
#import "BDCTTakePhotoBaseViewController.h"

@class BDCTImageManager, BDCTFlow;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTTakeOCRPhotoViewController : BDCTTakePhotoBaseViewController

@property (nonatomic, copy, nullable) void (^completionBlock)(NSDictionary *_Nullable ocrResult);
@property (nonatomic, strong) BDCTFlow *flow;

+ (instancetype)viewControllerWithParams:(NSDictionary *_Nonnull)params completion:(nullable void (^)(NSDictionary *_Nullable ocrResult))completion;

@end

NS_ASSUME_NONNULL_END
