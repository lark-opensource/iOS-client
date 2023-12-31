//
//  ACCMediaContainerViewProtocol.h
//  CameraClient
//
//  Created by imqiuhang on 2020/12/23.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@protocol ACCMediaContainerViewProtocol <NSObject>

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)builder;

- (void)resetView;

- (CGRect)mediaBigMediaFrameForSize:(CGSize)size;

- (BOOL)isPlayerContainsRect:(CGRect)rect;

- (void)updateOriginalFrameWithSize:(CGSize)size;

@property (nonatomic, assign, readonly) CGRect originalPlayerFrame;
@property (nonatomic, assign, readonly) CGRect editPlayerFrame;
@property (nonatomic, assign, readonly) CGRect videoContentFrame;
@property (nonatomic, assign, readonly) CGSize containerSize;
@property (nonatomic, assign) BOOL contentModeFit;

@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, strong, nullable) UIImageView *coverImageView;
@property (nonatomic, strong) UIActivityIndicatorView *boomerangIndicatorView;

@end

NS_ASSUME_NONNULL_END
