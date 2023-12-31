//
//  BytedCertCustomCam.h
//  Pods
//
//  Created by LiuChundian on 2019/6/17.
//

#ifndef BytedCertCustomCam_h
#define BytedCertCustomCam_h

#import <Foundation/Foundation.h>
#import "BDCTTakePhotoBaseViewController.h"


@interface BDCTTakePhotoViewController : BDCTTakePhotoBaseViewController
@property (nonatomic, copy, nullable) void (^completionBlock)(UIImage *_Nullable cropedImage, UIImage *_Nullable resultPhoto, NSDictionary *_Nullable metaData);

+ (void)takePhotoForType:(NSString *_Nullable)type completion:(nullable void (^)(UIImage *_Nullable cropedImage, UIImage *_Nullable resultPhoto, NSDictionary *_Nullable metaData))completion;

@end

#endif /* BytedCertCustomCam_h */
