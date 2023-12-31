//
//  ACCStickerLimitEdgeView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2021/1/29.
//

#import "ACCStickerLimitEdgeView.h"
#import "ACCImageAlbumEditorGeometry.h"

@interface ACCStickerLimitEdgeView ()

@property (nonatomic, strong) UIView *topEdgeView;
@property (nonatomic, strong) UIView *bottomEdgeView;

@end

@implementation ACCStickerLimitEdgeView
@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[ACCStickerLimitEdgeView alloc] initWithFrame:CGRectZero];
}

- (void)loadPlugin
{
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userInteractionEnabled = NO;
        _topEdgeView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor blackColor];
            [self addSubview:view];
            view;
        });
        
        _bottomEdgeView = ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = [UIColor blackColor];
            [self addSubview:view];
            view;
        });
    }
    
    return self;
}

#pragma mark - Public APIs
- (void)setContentSize:(CGSize)contentSize
{
    if (ACCImageEditSizeIsValid(contentSize)) {
        _contentSize = contentSize;
        [self updateEdgeView];
    }
}

- (void)updateEdgeView
{
    if (self.contentSize.height >= self.bounds.size.height) {
        self.topEdgeView.hidden = self.bottomEdgeView.hidden = YES;
    } else {
        CGFloat edgeHeight = (self.bounds.size.height-self.contentSize.height) / 2.0;
        self.topEdgeView.frame = CGRectMake(0, 0,
                                            self.bounds.size.width, edgeHeight);
        self.bottomEdgeView.frame = CGRectMake(0, self.bounds.size.height-edgeHeight,
                                               self.bounds.size.width, edgeHeight);
        self.topEdgeView.hidden = self.bottomEdgeView.hidden = NO;
    }
}

- (UIView *)pluginView
{
    return self;
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    self.frame = [self.stickerContainer containerView].bounds;
    [self updateEdgeView];
}

- (BOOL)featureSupportSticker:(nonnull id<ACCStickerProtocol>)sticker { 
    return YES;
}



- (void)didChangeLocationWithOperationStickerView:(nonnull ACCBaseStickerView *)stickerView { 
    
}

- (void)sticker:(nonnull ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView didEndGesture:(nonnull UIGestureRecognizer *)gesture { 
    
}

- (void)sticker:(nonnull ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView didHandleGesture:(nonnull UIGestureRecognizer *)gesture { 
    
}

- (void)sticker:(nonnull ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)stickerView willHandleGesture:(nonnull UIGestureRecognizer *)gesture { 
    
}

@end
