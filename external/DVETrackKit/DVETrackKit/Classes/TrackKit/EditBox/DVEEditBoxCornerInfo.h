//
//  DVEEditBoxCornerInfo.h
//  DVETrackKit
//
//  Created by pengzhenhuan on 2022/1/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DVEEditCornerType) {
    DVECornrDelete,
    DVECornerCopy,
    DVECornerMirror,
    DVECornerEdit,
    DVECornerPinch,
};

@interface DVEEditBoxCornerInfo : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) UIImage *highlightImage;
@property (nonatomic) DVEEditCornerType type;

- (instancetype)initWithImage:(UIImage *)image highlightImage:(UIImage *)hImage type:(DVEEditCornerType)type;

@end

NS_ASSUME_NONNULL_END
