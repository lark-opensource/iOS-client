//
//  AWEStickerPickerTabViewLayout.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/6.
//

#import "AWEStickerPickerTabViewLayout.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>

@interface AWEStickerPickerTabViewLayout ()

@end

@implementation AWEStickerPickerTabViewLayout

- (void)categoryViewLayoutWithContainerHeight:(CGFloat)height
                                        title:(nonnull NSString *)title
                                        image:(nonnull UIImage *)image
                                   completion:(nonnull void (^)(CGSize, CGRect, CGRect))completion {
    if (title.length == 0 && image == nil) {
        if (completion) {
            completion(CGSizeZero, CGRectZero, CGRectZero);
        }
        return;
    }
    if (height == 0.f) {
        if (completion) {
            completion(CGSizeZero, CGRectZero, CGRectZero);
        }
        return;
    }
    const CGFloat margin = 2.f;
    const CGFloat horizontalPadding = [self enableNewFavoritesTitle] ? 14.f : 16.f;
    
    CGSize textSize = [self titleLabelSizeWithTitle:title height:height];
    
    CGRect titleFrame = CGRectZero;
    titleFrame.size = textSize;
    CGRect imageFrame = CGRectZero;
    
    BOOL showImage = image && image.size.height > 0;
    BOOL showTitle = title.length > 0;
    if (showImage) {
        CGFloat imgWHRadio = image.size.width / image.size.height;
        CGFloat imgH = 24.f;
        CGSize imgSize = CGSizeMake(imgH*imgWHRadio, imgH);
        imageFrame.size = imgSize;
    }
    
    CGFloat cellWidth = 0.f;
    CGFloat imgX = 0.f;
    CGFloat titleX = 0.f;
    if (showImage && showTitle) {
        cellWidth = imageFrame.size.width + margin + textSize.width + 2 * horizontalPadding;
        imgX = horizontalPadding;
        titleX = imgX + imageFrame.size.width + margin;
    } else if (showImage) {
        cellWidth = imageFrame.size.width + 2 * horizontalPadding;
        imgX = horizontalPadding;
    } else if (showTitle) {
        cellWidth = textSize.width + 2 * horizontalPadding;
        titleX = horizontalPadding;
    }
    
    CGFloat imgY = (height - imageFrame.size.height) / 2;
    imageFrame.origin = CGPointMake(imgX, imgY);
    
    CGFloat titleY = (height - textSize.height) / 2;
    titleFrame.origin = CGPointMake(titleX, titleY);
    
    CGSize cellSize = CGSizeMake(cellWidth, height);
    
    if (completion) {
        completion(cellSize, titleFrame, imageFrame);
    }
}

- (CGSize)titleLabelSizeWithTitle:(NSString *)title height:(CGFloat)height {
    NSStringDrawingOptions opts = NSStringDrawingUsesLineFragmentOrigin;
    NSDictionary *attributes = @{
        NSFontAttributeName: [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightSemibold]
    };
    CGSize textSize = [title boundingRectWithSize:CGSizeMake(MAXFLOAT, height)
                                          options:opts
                                       attributes:attributes
                                          context:nil].size;
    textSize.width += 2;
    textSize.height = ceil(textSize.height) + 1;
    return textSize;
}

- (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

@end
