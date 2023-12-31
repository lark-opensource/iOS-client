//
//  ACCToolBarCommonViewLayout.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/1.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCToolBarViewLayoutDirection) {
    ACCToolBarCommonViewLayoutNone = 0,
    ACCToolBarViewLayoutDirectionHorizontal = 1,
    ACCToolBarViewLayoutDirectionVertical = 2
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarCommonViewLayout : NSObject

@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat moreButtonSpacing;
@property (nonatomic, assign) CGSize moreButtonSize;

@property (nonatomic, assign) ACCToolBarViewLayoutDirection direction;

@end

NS_ASSUME_NONNULL_END
