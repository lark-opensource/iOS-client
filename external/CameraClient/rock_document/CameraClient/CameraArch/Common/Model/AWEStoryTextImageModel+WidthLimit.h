//
//  AWEStoryTextImageModel+WidthLimit.h
//  CameraClient-Pods-Aweme
//
//  Created by shaohua on 2021/5/29.
//

#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStoryTextImageModel (WidthLimit)

@property (nonatomic, assign) CGFloat widthLimit; // default is 0: not specified

@end

NS_ASSUME_NONNULL_END
