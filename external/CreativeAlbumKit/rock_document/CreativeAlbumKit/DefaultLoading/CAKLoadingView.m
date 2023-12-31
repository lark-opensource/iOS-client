//
//  CAKLoadingView.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/14.
//

#import "CAKLoadingView.h"
#import "UIColor+AlbumKit.h"
#import "UIImage+AlbumKit.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/Masonry.h>
#import <objc/runtime.h>

@interface CAKLoadingView()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, assign) CAKLoadingViewStatus status;

@end

@implementation CAKLoadingView

- (instancetype)init
{
    self = [self initWithFrame:CGRectMake(0, 0, 32, 32)];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _status = CAKLoadingViewStatusStop;
        [self setupUIWithBackground:NO];
        [self addObservers];
    }
    return self;
}

- (instancetype)initWithBackground
{
    self = [super initWithFrame:CGRectMake(0, 0, 80, 80)];
    if (self) {
        _status = CAKLoadingViewStatusStop;
        self.backgroundColor = CAKResourceColor(ACCColorToastDefault);
        self.layer.cornerRadius = 4;
        self.layer.masksToBounds = YES;
        [self setupUIWithBackground:YES];
        [self addObservers];
    }
    return self;
}

- (instancetype)initWithBackgroundAndDisableUserInteraction
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.userInteractionEnabled = YES;
        _status = CAKLoadingViewStatusStop;
        UIView *containerView = [[UIView alloc] init];
        [self addSubview:containerView];
        ACCMasMaker(containerView, {
            make.center.equalTo(self);
            make.size.equalTo(@(CGSizeMake(80, 80)));
        });
        containerView.backgroundColor = CAKResourceColor(ACCColorToastDefault);
        containerView.layer.cornerRadius = 4;
        containerView.layer.masksToBounds = YES;
        [containerView addSubview:self.imageView];
        ACCMasMaker(self.imageView, {
            make.center.equalTo(containerView);
        });
        [self addObservers];
    }
    return self;
}

- (instancetype)initWithDisableUserInteraction
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.userInteractionEnabled = YES;
        _status = CAKLoadingViewStatusStop;
        [self addSubview:self.imageView];
        ACCMasMaker(self.imageView, {
            make.center.equalTo(self);
        });
        [self addObservers];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupUIWithBackground:(BOOL)hasBackground
{
    [self addSubview:self.imageView];
    ACCMasMaker(self.imageView, {
        if (hasBackground) {
            make.center.equalTo(self);
        } else {
            make.edges.equalTo(self);
        }
    });
}

- (void)startAnimating
{
    NSArray *animatedImages = [self animatedImages];
    if (animatedImages.count <= 0) {
        return;
    }
    NSInteger currentIndex = (NSInteger)floor(self.progress * (animatedImages.count - 1));
    if (currentIndex > 0) {
        animatedImages = [[animatedImages subarrayWithRange:NSMakeRange(currentIndex, animatedImages.count - currentIndex)] arrayByAddingObjectsFromArray:[animatedImages subarrayWithRange:NSMakeRange(0, currentIndex - 1)]];
    }
    self.imageView.animationImages = animatedImages;
    self.imageView.animationDuration = 1;
    [self.imageView startAnimating];
    self.status = CAKLoadingViewStatusAnimating;
}

- (void)stopAnimating
{
    [self.imageView stopAnimating];
    self.status = CAKLoadingViewStatusStop;
}

- (void)dismissWithAnimated:(BOOL)animated
{
    void (^dismissBlock)(void) = ^ {
        self.status = CAKLoadingViewStatusStop;
        [self removeFromSuperview];
    };
    if (animated) {
        self.alpha = 1;
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            dismissBlock();
        }];
    } else {
        self.alpha = 0;
        dismissBlock();
    }
}

- (void)dismiss
{
    [self dismissWithAnimated:NO];
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = CAKResourceImage([self animatedImageNames].firstObject);
    }
    return _imageView;
}

- (NSArray<NSString *> *)animatedImageNames
{
    static NSMutableArray<NSString *> *imageNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageNames = [NSMutableArray array];
        for (NSInteger i = 0; i < 2; i++) {
            NSString *name = [NSString stringWithFormat:@"Loading__0000%ld", (long)i];
            [imageNames acc_addObject:name];
        }
    });
    return imageNames;
}

- (NSArray<UIImage *> *)animatedImages
{
    static NSMutableArray *loadingImages;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadingImages = [NSMutableArray array];
        NSArray *imageNamesArray = [self animatedImageNames];
        for (NSString *imageName in imageNamesArray) {
            UIImage *image = CAKResourceImage(imageName);
            if (image) {
                [loadingImages acc_addObject:image];
            }
        }
    });
    return loadingImages;
}


#pragma mark - Private

- (void)setProgress:(CGFloat)progress
{
    if (progress < 0) {
        progress = 0;
    } else if (progress > 1) {
        progress -= floor(progress);
    }
    _progress = progress;
    NSInteger imageIndex = (NSInteger)floor(progress * 59);
    if (imageIndex < [[self animatedImages] count] && imageIndex >= 0) {
        self.imageView.image = [self animatedImages][imageIndex];
    }
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)appWillEnterForeground
{
    if (self.status == CAKLoadingViewStatusAnimating) {
        [self startAnimating];
    }
}

@end
