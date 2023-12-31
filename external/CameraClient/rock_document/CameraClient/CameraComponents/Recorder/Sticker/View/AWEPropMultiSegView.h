//
//  AWEPropMultiSegView.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, AWEPropMultiSegViewState) {
    AWEPropMultiSegViewStateNone,
    AWEPropMultiSegViewStateProcessing,
    AWEPropMultiSegViewStateCompleted,
};

@interface AWEPropMultiSegView : UIView

@property (nonatomic, assign) AWEPropMultiSegViewState state;

@property (nonatomic, strong) UIImageView *completeImageView;
@property (nonatomic, strong) UIImageView *bottomImageView;

@property (nonatomic, strong) UILabel *secondsLabel;

@property (nonatomic, strong) UIView *grayCoverView;

@end

NS_ASSUME_NONNULL_END
