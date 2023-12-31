//
//  DVEAudioSegmentTag.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioSegmentTag : UIView

- (void)updateText:(NSString *)text;

- (void)updateImage:(UIImage*)image;

- (void)updateImageURL:(NSString*)imageURL;

@end

NS_ASSUME_NONNULL_END
