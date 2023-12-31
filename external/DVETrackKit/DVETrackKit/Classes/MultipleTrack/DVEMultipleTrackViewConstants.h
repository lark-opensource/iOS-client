//
//  DVEMultipleTrackViewConstants.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackViewConstants : NSObject

@property (nonatomic, assign, class, readonly) CGFloat minRecordSecond;
@property (nonatomic, assign, class, readonly) CGFloat splitSpace;
@property (nonatomic, assign, class, readonly) CGFloat minLayoutHeight;
@property (nonatomic, assign, class, readonly) CGFloat cellSectionSpace;
@property (nonatomic, assign, class, readonly) CGFloat cornerRadius;
@property (nonatomic, strong, class, readonly) UIFont *titleFont;
@property (nonatomic, strong, class, readonly) UIFont *soundTitleFont;

// emoji 贴纸用titleLabel 来展示，需要放大一些
@property (nonatomic, strong, class, readonly) UIFont *emojiTitleFont;
@property (nonatomic, strong, class, readonly) UIColor *titleTextColor;
@property (nonatomic, strong, class, readonly) UIColor *titleBackgroundTextColor;
@property (nonatomic, strong, class, readonly) NSString *cellIdentifier;


@end

NS_ASSUME_NONNULL_END
