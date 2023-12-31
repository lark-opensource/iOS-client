//
//  AWEVideoEditStickerHeaderView.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/2/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoEditStickerHeaderView : UIView

- (void)updateWithTitles:(NSArray *)titles;
- (void)updateWithAttributes:(NSArray *)attributes yOffset:(CGFloat)yOffset;

+ (CGFloat)headerHeight;

@end

NS_ASSUME_NONNULL_END
