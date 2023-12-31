//
//  BDImageView.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/29.
//

#import "BDImageView.h"
#import "BDAnimatedImagePlayer.h"
#import "UIImageView+BDWebImage.h"
#import <pthread/pthread.h>
#import "UIImage+BDWebImage.h"

@interface BDImageView()<BDAnimatedImagePlayerDelegate>
@property (nonatomic, strong) BDAnimatedImagePlayer *player;
@property (nonatomic, strong) BDImage *animateImage;
@end


@implementation BDImageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _animateEnable = YES;
        _frameCacheAutomatically = YES;
        _autoPlayAnimatedImage = YES;
        _hightAnimationControl = YES;
        _moveToWindowAnimationControl = NO;
        _animationType = BDAnimatedImageAnimationTypeOrder;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _animateEnable = YES;
        _frameCacheAutomatically = YES;
        _autoPlayAnimatedImage = YES;
        _animateRunLoopMode = NSRunLoopCommonModes;
        _animationType = BDAnimatedImageAnimationTypeOrder;
    }
    return self;
}

- (void)setImageForIOS13:(UIImage *)image new:(BOOL)newImage
{
    if (newImage) {
        if (!image) {
            self.animateImage = nil;
            [self stopAnimation];
            [super setImage:nil];
            return;
        }
        if (image == self.animateImage) {
            return;
        }
        if (self.animateImage) {
            self.animateImage = nil;
            [self stopAnimation];
        }
        
        if ([image isKindOfClass:[BDImage class]] && [(BDImage *)image isAnimateImage]) {
            self.animateImage = (BDImage *)image;
        }
        
        [super setImage:image];
        
        if (_animateEnable && _autoPlayAnimatedImage) {
            [self _tryPlayAnimateImage];
        }
    }
    else if (!self.isHighlighted ||
             (self.highlighted && !self.highlightedImage)) {
        if (image) {
            self.layer.contents = (__bridge id _Nullable)(image.CGImage);
        }
    }
}

- (void)setImage:(UIImage *)image new:(BOOL)newImage
{
    if (@available(iOS 13.0, *)) {
        [self setImageForIOS13:image new:newImage];
        return;
    }
    
    [super setImage:image];
    
    if (newImage && image != self.animateImage) {
        if (self.animateImage) {
            self.animateImage = nil;
            [self stopAnimation];
        }
        
        if ([image isKindOfClass:[BDImage class]] && [(BDImage *)image isAnimateImage]) {
            self.animateImage = (BDImage *)image;
        }
        
        [super setImage:image];
        
        if (_animateEnable && _autoPlayAnimatedImage) {
            [self _tryPlayAnimateImage];
        }
    }
    else if (!self.isHighlighted ||
             (self.highlighted && !self.highlightedImage)) {
        if (image) {
            self.layer.contents = (__bridge id _Nullable)(image.CGImage);
        }
    }
}

- (void)setImage:(UIImage *)image
{
    if (_animateImage && _player &&
        [image isKindOfClass:[BDImage class]] &&
        _animateImage.bd_loading &&
        [_animateImage.bd_requestKey isEqual:image.bd_requestKey]) {

        self.animateImage = (BDImage *)image;
        [_player updateProgressImage:(BDImage *)image];

    } else {
        [self setImage:image new:YES];
    }
}

- (UIImage *)image
{
    if (_animateImage) {
        return _animateImage;
    }
    return [super image];
}

#pragma mark - overwrite Method

- (void)startAnimating
{
    if (self.animateImage) {
        [self startAnimation];
    } else {
        [super startAnimating];
    }
}

- (void)stopAnimating
{
    if (self.animateImage) {
        [self pauseAnimation];
    } else {
        [super stopAnimating];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    //感觉有些不需要自动播放的应该限制一下
    if (self.window && self.autoPlayAnimatedImage) {
        [self _tryPlayAnimateImage];
    } else {
        if (self.moveToWindowAnimationControl) {
            // pauseAnimation 保留动图播放信息（第x帧），下次能继续在第x帧开始播放
            [self pauseAnimation];
        } else {
            [self stopAnimation];
        }
    }
}

- (void)dealloc
{
    _animateImage = nil;
    _player.delegate = nil;
    [_player stopPlay];
    _player = nil;
}

//点击 UIImageView 会调用到 setHighlighted，系统会调用 [UIImageView stopAnimating]
- (void)setHighlighted:(BOOL)highlighted
{
    if (self.hightAnimationControl) {
        if (self.animateImage) {
            if (highlighted && self.highlightedImage) {
                [self stopAnimating];
            }
            else {
                [self _tryPlayAnimateImage];
            }
        }
    }
    [super setHighlighted:highlighted];
}

#pragma mark - public Method

- (void)pauseAnimation
{
    if (_player) {
        [_player pause];
    }
}

- (void)startAnimation
{
    [self _tryPlayAnimateImage];
}

- (void)stopAnimation
{
    if (_player) {
        [_player stopPlay];
        _player = nil;
    }
    if (self.animateImage) {
        [self setImage:self.animateImage new:NO];
    }
}

- (void)setCurrentAnimatedImageIndex:(NSUInteger)currentAnimatedImageIndex
{
    _player.currentIndex = currentAnimatedImageIndex;
}

- (NSUInteger)currentAnimatedImageIndex
{
    return _player.currentFrame.index;
}

#pragma mark -  Core Private Method


- (void)_tryPlayAnimateImage
{
    if (!self.window) {
        return;
    }
    
    if (self.animateImage && _animateEnable) {
        [self.player startPlay];
    }
}

#pragma mark - BDAnimatedImagePlayerDelegate

- (void)imagePlayerStartPlay:(BDAnimatedImagePlayer *)player {
    if (self.firstFramePlayBlock) {
        self.firstFramePlayBlock(player.image.bd_webURL.absoluteString);
    }
}

- (void)imagePlayer:(BDAnimatedImagePlayer *)Player didUpdateImage:(UIImage *)image index:(NSUInteger)index
{
    if ([self.imageRequest.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)]) {
        [self setImage:[self.imageRequest.transformer transformImageBeforeStoreWithImage:image] new:NO];
    }else  {
        [self setImage:image new:NO];
    }
}

- (void)imagePlayerDidReachEnd:(BDAnimatedImagePlayer *)player {
    if (self.loopCompletionBlock) {
        self.loopCompletionBlock();
    }
}

- (void)imagePlayerDelayPlay:(BDAnimatedImagePlayer *)player
                       index:(NSUInteger)index
          animationDelayType:(BDProgressiveAnimatedImageDelayType)animationDelayType
         animationDelayState:(BDProgressiveAnimatedImageDelayState)animationDelayState{
    if (self.delayFramePlayBlock){
        self.delayFramePlayBlock(index, animationDelayType, animationDelayState);
    }
}

- (void)imagePlayerDidReachAllLoopEnd:(BDAnimatedImagePlayer *)player{
    if (self.customLoopCompletionBlock) {
        self.customLoopCompletionBlock();
    }
}

#pragma mark - Accessor

- (void)setCustomLoop:(NSUInteger)customLoop {
    if (_customLoop != customLoop) {
        _customLoop = customLoop;
        if (_player) {
            [_player setLoopCount:_customLoop];
        }
    }
}

- (BDAnimatedImagePlayer *)player
{
    if (!_player && self.animateImage) {
        _player = [BDAnimatedImagePlayer playerWithImage:self.animateImage];
        _player.animationType = self.animationType;

        if (_customLoop > 0) {
            // 当边下边播的时候设置customLoop，之后将其值赋值给loopCount
            [_player setCustomLoopCount:_customLoop];
            // 当采用普通方式播放的时候直接设置loopCount
            [_player setLoopCount:_customLoop];
        }
        else if (_infinityLoop) {
            [_player setLoopCount:NSIntegerMax];
        }
        _player.frameCacheAutomatically = self.frameCacheAutomatically;
        _player.cacheAllFrame = self.cacheAllFrame;
        _player.animateRunLoopMode = self.animateRunLoopMode;
        _player.delegate = self;
    }
    return _player;
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<BDImageView: %p; frame=(%d %d; %d %d); imageUrl=%@>", self, (int)self.frame.origin.x, (int)self.frame.origin.y, (int)self.frame.size.width, (int)self.frame.size.height, [self.image bd_webURL]];
}
@end
