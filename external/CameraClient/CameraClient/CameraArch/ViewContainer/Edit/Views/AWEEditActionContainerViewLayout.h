//
//  AWEEditActionContainerViewLayout.h
//  Pods
//
//  Created by 赖霄冰 on 2019/7/8.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AWEEditActionContainerViewLayoutDirection) {
    AWEEditActionContainerViewLayoutDirectionHorizontal,
    AWEEditActionContainerViewLayoutDirectionVertical
};

NS_ASSUME_NONNULL_BEGIN

@interface AWEEditActionContainerViewLayout : NSObject <NSCopying>

@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) UIEdgeInsets containerInset;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) AWEEditActionContainerViewLayoutDirection direction;
@property (nonatomic, assign) NSInteger foldExihibitCount;

@end

NS_ASSUME_NONNULL_END
