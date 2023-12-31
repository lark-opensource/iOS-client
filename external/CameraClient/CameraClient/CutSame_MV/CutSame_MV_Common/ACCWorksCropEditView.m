//
//  ACCWorksCropEditView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/3.
//

#import "AWERepoCutSameModel.h"
#import "ACCWorksCropEditView.h"

#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCButton.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>

#import "ACCPlaybackView.h"
#import "ACCCutSamePlayerControlView.h"
#import "ACCCutSameCropMaskView.h"
#import "AVAsset+MV.h"

#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>

static CGFloat const ACCWorksCropEditViewCropXGap = 32.0;
static CGFloat const ACCWorksCropEditViewCropVideoYGap = 24.0;
static CGFloat const ACCWorksCropEditViewCropImageYGap = 40.0;
static CGFloat const ACCWorksCropEditViewCropImageButtonYGap = 68.0;

@interface ACCWorksCropEditView ()<UIScrollViewDelegate>

@property (nonatomic, strong) id<ACCCutSameStylePreviewFragmentProtocol> fragment;

@property (nonatomic, strong) UIScrollView *containerScrollView;

@property (nonatomic, strong) UIImageView *videoImageView;
@property (nonatomic, assign) CGSize videoImageSize;

@property (nonatomic, strong) ACCCutSamePlayerControlView *videoPlayerControlView;
@property (nonatomic, strong) ACCPlaybackView *videoPlayerView;
@property (nonatomic, assign) CGSize videoOriginalSize;
@property (nonatomic, assign) CMTime startTime;
@property (nonatomic, assign) CMTime endTime;
@property (nonatomic, assign) CMTime curTimeOffset;
@property (nonatomic, strong) id playerObserver;

@property (nonatomic, strong) ACCCutSameCropMaskView *cropMaskView;
@property (nonatomic, assign) CGRect cropMaskRect;

@property (nonatomic, strong) ACCButton *changeMaterialButton;

@property (nonatomic, assign) BOOL isPauseByOthers;

@property (nonatomic, assign) BOOL isPauseByDisappear;

@property (nonatomic, assign) BOOL canScale;

@property (nonatomic, assign, readwrite) BOOL didModified;

@end

@implementation ACCWorksCropEditView

- (void)dealloc
{
    [_videoPlayerView.player removeTimeObserver:_playerObserver];
}

- (instancetype)initWithFrame:(CGRect)frame fragment:(id<ACCCutSameStylePreviewFragmentProtocol>)fragment canScale:(BOOL)canScale
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.canScale = canScale;
        
        self.containerScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        [self addSubview:self.containerScrollView];
        self.containerScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.containerScrollView.showsVerticalScrollIndicator = NO;
        self.containerScrollView.showsHorizontalScrollIndicator = NO;
        [self.containerScrollView acc_addSingleTapRecognizerWithTarget:self action:@selector(p_handleContainerViewTapped:)];
        if (@available(iOS 11.0, *)) {
            self.containerScrollView.insetsLayoutMarginsFromSafeArea = NO;
            self.containerScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        
        if (canScale) {
            self.containerScrollView.delegate = self;
            self.containerScrollView.maximumZoomScale = CGFLOAT_MAX;
            [self addSubview:self.cropMaskView];
        } else {
            self.containerScrollView.scrollEnabled = NO;
        }
        
        [self addSubview:self.changeMaterialButton];
        
        self.curTimeOffset = kCMTimeZero;
        self.fragment = fragment;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_appWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_appDidBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)play
{
    self.isPauseByOthers = NO;
    [_videoPlayerView.player play];
}

- (void)pause
{
    self.isPauseByOthers = YES;
    [_videoPlayerView.player pause];
}

- (void)playIfPauseBySlide
{
    if (!self.isPauseByOthers) {
        [_videoPlayerView.player play];
    }
}

- (void)pauseBySlide
{
    [_videoPlayerView.player pause];
}


- (void)playIfPauseByDisappear
{
    if (!self.isPauseByOthers && self.isPauseByDisappear) {
        self.isPauseByDisappear = NO;
        [_videoPlayerView.player play];
    }
}

- (void)pauseByDisappear
{
    self.isPauseByDisappear = YES;
    [_videoPlayerView.player pause];
}

- (void)seekToTime:(CMTime)time
{
    CMTime newTime = CMTimeAdd(self.startTime, time);
    if (CMTimeCompare(newTime, self.endTime) >= 0) {
        newTime = CMTimeSubtract(self.endTime, CMTimeMake(1, NSEC_PER_MSEC));
    }
    
    [self.videoPlayerView.player seekToTime:newTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)reset
{
    if (self.videoAsset) {
        [_videoImageView removeFromSuperview];
        _videoImageView = nil;
    } else {
        [_videoPlayerView.player removeTimeObserver:self.playerObserver];
        [_videoPlayerView removeFromSuperview];
        _videoPlayerView = nil;
    }
    
    self.containerScrollView.zoomScale = 1.0;
    self.containerScrollView.minimumZoomScale = 1.0;
    if (self.canScale) {
        self.containerScrollView.maximumZoomScale = CGFLOAT_MAX;
    } else {
        self.containerScrollView.maximumZoomScale = 1.0;
    }
    
    [self refreshFrame];
    [self refreshTime];
}


- (void)changeTimeOffest:(CMTime)offsetTime
{
    if (self.videoAsset) {
        CMTimeRange range = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange;
        self.startTime = CMTimeAdd(range.start, offsetTime);
        self.endTime = CMTimeAdd(self.startTime, self.fragment.duration);
        CMTime cmpTime = CMTimeAdd(range.start, range.duration);
        if (CMTimeCompare(self.endTime, cmpTime) > 0) {
            self.endTime = cmpTime;
        }
        
        [_videoPlayerView.player seekToTime:CMTimeAdd(self.startTime, self.curTimeOffset) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

- (CMTimeRange)currentTimeRange
{
    CMTimeRange range = [self.videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject.timeRange;
    CMTime cmpEndTime = CMTimeAdd(range.start, range.duration);
    
    CMTime startTime = self.startTime, endTime = self.endTime;
    
    if (CMTimeCompare(endTime, cmpEndTime) == 0) {
        startTime = CMTimeSubtract(cmpEndTime, self.fragment.duration);
        if (CMTimeCompare(startTime, kCMTimeZero) < 0) {
            startTime = kCMTimeZero;
        }
    }
    
    return CMTimeRangeFromTimeToTime(startTime, endTime);
}

#pragma mark - Setter
- (void)setImageFileURL:(NSURL *)imageFileURL
{
    if (_imageFileURL != imageFileURL) {
        _imageFileURL = [imageFileURL copy];
        
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageFileURL]];
        self.videoImageView.image = image;
        self.videoImageSize = image.size;
        self.changeMaterialButton.hidden = NO;
    }
}

- (void)setVideoAsset:(AVURLAsset *)videoAsset
{
    if (_videoAsset != videoAsset) {
        _videoAsset = videoAsset;
        
        if (videoAsset) {
            @weakify(self);
            self.changeMaterialButton.hidden = YES;
            self.videoOriginalSize = [videoAsset mv_videoSize];
            
            AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:videoAsset];
            AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:item];
            
            [self.videoPlayerView.player removeTimeObserver:self.playerObserver];
            self.playerObserver =
            [player
             addPeriodicTimeObserverForInterval:CMTimeMake(1, 60)
             queue:dispatch_get_main_queue()
             usingBlock:^(CMTime time) {
                @strongify(self);
                self.curTimeOffset = CMTimeSubtract(time, self.startTime);
                ACCBLOCK_INVOKE(self.playTimeCallback, CMTimeSubtract(time, self.startTime));
                
                [self didPlayTime:time];
            }];
            
            self.videoPlayerView.player = player;
            [player play];
            [self videoPlayerControlView];
        }
    }
}

- (void)setFragment:(id<ACCCutSameStylePreviewFragmentProtocol>)fragment
{
    if (_fragment != fragment) {
        _fragment = fragment;
        
        [self refreshTime];
    }
}

- (void)setPreferredSize:(CGSize)preferredSize
{
    if (!CGSizeEqualToSize(_preferredSize, preferredSize)) {
        _preferredSize = preferredSize;
        
//        [self refreshFrame];
    }
}

#pragma mark - Getter
- (UIImageView *)videoImageView
{
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self.containerScrollView addSubview:_videoImageView];
    }
    
    return _videoImageView;
}

- (ACCPlaybackView *)videoPlayerView
{
    if (!_videoPlayerView) {
        _videoPlayerView = [[ACCPlaybackView alloc] initWithFrame:self.bounds];
        [self.containerScrollView addSubview:_videoPlayerView];
    }
    
    return _videoPlayerView;
}

- (ACCCutSamePlayerControlView *)videoPlayerControlView
{
    if (!_videoPlayerControlView) {
        _videoPlayerControlView = [[ACCCutSamePlayerControlView alloc] initWithFrame:self.videoPlayerView.bounds];
        _videoPlayerControlView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _videoPlayerControlView.userInteractionEnabled = NO;
        [self addSubview:_videoPlayerControlView];
    }
    
    return _videoPlayerControlView;
}

- (ACCCutSameCropMaskView *)cropMaskView
{
    if (!_cropMaskView) {
        _cropMaskView = [[ACCCutSameCropMaskView alloc] initWithFrame:self.bounds isBlackMask:!self.canScale];
        [_cropMaskView animateForBlurEffect:YES animate:NO];
        _cropMaskView.userInteractionEnabled = NO;
    }
    
    return _cropMaskView;
}

- (ACCButton *)changeMaterialButton
{
    if (!_changeMaterialButton) {
        ACCButton *btn = [ACCButton buttonWithSelectedAlpha:0.5];
        self.changeMaterialButton = btn;
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = 2;
        [btn setTitleColor:ACCResourceColor(ACCColorConstTextInverse2) forState:UIControlStateNormal];
        [btn acc_setBackgroundColor:ACCResourceColor(ACCColorConstBGContainer5) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(onChangeMaterialAction:) forControlEvents:UIControlEventTouchUpInside];

        btn.adjustsImageWhenHighlighted = NO;
        btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12);
        [btn setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [btn setTitle:ACCLocalizedCurrentString(@"mv_items_change") forState:UIControlStateNormal];
        CGSize size = [btn sizeThatFits:CGSizeMake(CGFLOAT_MAX, 28.0)];
        btn.frame = CGRectMake(self.bounds.size.width/2.0 - (size.width+12.0)/2.0,
                               self.bounds.size.height-28.0-40.0,
                               size.width+12.0,
                               28.0);
        btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
        btn.hidden = YES;
    }
    
    return  _changeMaterialButton;
}

#pragma mark - track

- (void)trackForCropImageAsset:(AWEVideoPublishViewModel *)publishModel;
{
    // 缩放、拖动结束时上报
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"mv_edit_page";
    params[@"shoot_way"] = publishModel.repoTrack.referString ? : @"";
    params[@"content_source"] =  @"upload";
    params[@"content_type"] = [self contentTypeFromModel:publishModel];
    params[@"creation_id"] = publishModel.repoContext.createId ?: @"";
    params[@"mv_id"] = publishModel.repoMV.templateModelId ?: @"";
    
    [params addEntriesFromDictionary:[publishModel.repoCutSame smartVideoAdditonParamsForTrack]];

    [ACCTracker() trackEvent:@"edit_mv_pic" params:[params copy]];
}

- (NSString *)contentTypeFromModel:(AWEVideoPublishViewModel *)publishModel
{
    if (publishModel.repoContext.videoType == AWEVideoTypeMV && publishModel.repoCutSame.accTemplateType == ACCMVTemplateTypeCutSame) {
        return @"jianying_mv";
    } else if (publishModel.repoContext.videoType == AWEVideoTypeMV && publishModel.repoCutSame.isClassicalMV) {
        return @"mv";
    }
    
    switch (publishModel.repoContext.videoType) {
        case AWEVideoTypeMoments:
            return @"moment";
            break;
        case AWEVideoTypeSmartMV:
            return @"smart_mv";
            break;
        case AWEVideoTypeOneClickFilming:
            return @"ai_upload";
            break;
            
        default:
            break;
    }
    
    return @"";
}

#pragma mark -
//- (void)layoutSubviews
//{
//    [super layoutSubviews];
//
//    [self refreshFrame];
//}

- (void)refreshFrame
{
    CGFloat expectedHeight = 0.0;
    CGFloat const expectedWidth = self.bounds.size.width - 2*ACCWorksCropEditViewCropXGap;
    if (self.canScale) {
        if (_videoImageView.image) {
            expectedHeight = self.bounds.size.height - 2*ACCWorksCropEditViewCropImageYGap - ACC_STATUS_BAR_HEIGHT - ACCWorksCropEditViewCropImageButtonYGap;
        } else {
            expectedHeight = self.bounds.size.height - 2*ACCWorksCropEditViewCropVideoYGap - ACC_STATUS_BAR_HEIGHT;
        }
        
        
        CGFloat newHeight = 0.0, newWidth = 0.0;
        
        CGFloat newWidth1 = expectedWidth;
        CGFloat newHeight1 = 0 ;
        if (self.preferredSize.width > 0) {
            newHeight1 = self.preferredSize.height/self.preferredSize.width * newWidth1;
        }
        
        CGFloat newHeight2 = expectedHeight;
        CGFloat newWidth2 = 0;
        if (self.preferredSize.height > 0) {
             newWidth2 = self.preferredSize.width/self.preferredSize.height * newHeight2;
        }
        
        if (newHeight1 > expectedHeight) {
            newWidth = newWidth2;
            newHeight = newHeight2;
        } else if (newWidth2 > expectedWidth) {
            newWidth = newWidth1;
            newHeight = newHeight1;
        } else {
            if (newWidth1 > newWidth2) {
                newWidth = newWidth1;
                newHeight = newHeight1;
            } else {
                newWidth = newWidth2;
                newHeight = newHeight2;
            }
        }
        
        CGFloat limitY = 0.0;
        if (_videoImageView.image) {
            if (ceil((self.bounds.size.height-newHeight) / 2.0) < ACC_STATUS_BAR_HEIGHT+ACCWorksCropEditViewCropImageYGap) {
                limitY = ACC_STATUS_BAR_HEIGHT+ACCWorksCropEditViewCropImageYGap - ceil((self.bounds.size.height-newHeight) / 2.0);
            }
        } else {
            if (ceil((self.bounds.size.height-newHeight) / 2.0) < ACC_STATUS_BAR_HEIGHT+ACCWorksCropEditViewCropVideoYGap) {
                limitY = ACC_STATUS_BAR_HEIGHT+ACCWorksCropEditViewCropVideoYGap - ceil((self.bounds.size.height-newHeight) / 2.0);
            }
        }
        
        self.cropMaskRect = CGRectMake(ceil((self.bounds.size.width-newWidth) / 2.0),
                                       ceil((self.bounds.size.height-newHeight) / 2.0) + limitY,
                                       newWidth,
                                       newHeight);
        self.cropMaskView.frameSize = self.cropMaskRect.size;
        self.cropMaskView.offset = CGPointMake(0.0, limitY);
        self.cropMaskView.frame = self.bounds;
        self.cropMaskView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        
        if (_videoImageView.image) {
            CGSize imageSize = self.videoImageSize;
            self.videoImageView.frame = CGRectMake(0, 0, imageSize.width, imageSize.height);
            self.containerScrollView.contentInset = UIEdgeInsetsMake(self.cropMaskRect.origin.y,
                                                                     self.cropMaskRect.origin.x,
                                                                     self.containerScrollView.bounds.size.height - CGRectGetMaxY(self.cropMaskRect),
                                                                     self.cropMaskRect.origin.x);
            self.containerScrollView.contentSize = imageSize;
            
            [self reverseCrops];
        } else if (_videoPlayerView) {
            CGSize videoSize = self.videoOriginalSize;
            self.videoPlayerView.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
            self.containerScrollView.contentInset = UIEdgeInsetsMake(self.cropMaskRect.origin.y,
                                                                     self.cropMaskRect.origin.x,
                                                                     self.containerScrollView.bounds.size.height - CGRectGetMaxY(self.cropMaskRect),
                                                                     self.cropMaskRect.origin.x);
            self.containerScrollView.contentSize = videoSize;
            
            [self reverseCrops];
        }
        self.didModified = NO;
    } else {
        if (_videoImageView.image) {
            expectedHeight = self.bounds.size.height - 2*ACCWorksCropEditViewCropImageYGap - ACC_STATUS_BAR_HEIGHT - ACCWorksCropEditViewCropImageButtonYGap;
        } else {
            expectedHeight = self.bounds.size.height - ACC_STATUS_BAR_HEIGHT;
        }
        
        CGFloat newHeight = 0.0, newWidth = 0.0;
        
        CGSize targetSize = CGSizeZero;
        if (_videoImageView.image) {
            targetSize = self.videoImageSize;
        } else if (_videoPlayerView) {
            targetSize = self.videoOriginalSize;
        }
        
        CGFloat newWidth1 = expectedWidth;
        CGFloat newHeight1 = targetSize.height/targetSize.width * newWidth1;
        
        CGFloat newHeight2 = expectedHeight;
        CGFloat newWidth2 = targetSize.width/targetSize.height * newHeight2;
        
        if (newHeight1 > expectedHeight) {
            newWidth = newWidth2;
            newHeight = newHeight2;
        } else if (newWidth2 > expectedWidth) {
            newWidth = newWidth1;
            newHeight = newHeight1;
        } else {
            if (newWidth1 > newWidth2) {
                newWidth = newWidth1;
                newHeight = newHeight1;
            } else {
                newWidth = newWidth2;
                newHeight = newHeight2;
            }
        }
        
        if (_videoImageView.image) {
            self.videoImageView.frame = CGRectMake((self.containerScrollView.bounds.size.width-newWidth) / 2.0,
                                                   (self.containerScrollView.bounds.size.height-newHeight-ACC_STATUS_BAR_HEIGHT-ACCWorksCropEditViewCropImageButtonYGap) / 2.0 + ACC_STATUS_BAR_HEIGHT,
                                                   newWidth,
                                                   newHeight);
        } else if (_videoPlayerView) {
            self.videoPlayerView.frame = CGRectMake((self.containerScrollView.bounds.size.width-newWidth) / 2.0,
                                                    (self.containerScrollView.bounds.size.height-newHeight-ACC_STATUS_BAR_HEIGHT) / 2.0 + ACC_STATUS_BAR_HEIGHT,
                                                    newWidth,
                                                    newHeight);
        }
    }
}

- (void)refreshTime
{
    self.startTime = _fragment.start;
    self.endTime = CMTimeAdd(self.startTime, _fragment.duration);
    self.curTimeOffset = kCMTimeZero;
}

- (NSArray<NSValue *> *)currentCrops
{
    if (!self.canScale) {
        return nil;
    }
    
    CGFloat curW = self.cropMaskRect.size.width/self.containerScrollView.zoomScale;
    CGFloat curH = self.cropMaskRect.size.height/self.containerScrollView.zoomScale;
    CGFloat curX = (self.containerScrollView.contentOffset.x+self.containerScrollView.contentInset.left)/self.containerScrollView.zoomScale;
    CGFloat curY = (self.containerScrollView.contentOffset.y+self.containerScrollView.contentInset.top)/self.containerScrollView.zoomScale;
    
    CGFloat pX, pY, pW, pH;
    if (_videoImageView.image) {
        pX = curX/self.videoImageSize.width;
        pY = curY/self.videoImageSize.height;
        pW = curW/self.videoImageSize.width;
        pH = curH/self.videoImageSize.height;
    } else {
        pX = curX/self.videoOriginalSize.width;
        pY = curY/self.videoOriginalSize.height;
        pW = curW/self.videoOriginalSize.width;
        pH = curH/self.videoOriginalSize.height;
    }
    
    if (pX < 0.0) {
        pX = 0.0;
    }
    
    if (pY < 0.0) {
        pY = 0.0;
    }
    
    CGFloat bigX = pX + pW;
    if (bigX > 1.0) {
        bigX = 1.0;
    }
    CGFloat bigY = pY + pH;
    if (bigY > 1.0) {
        bigY = 1.0;
    }
    
    NSArray *result = @[
        [NSValue valueWithCGPoint:CGPointMake(pX, pY)],
        [NSValue valueWithCGPoint:CGPointMake(bigX, pY)],
        [NSValue valueWithCGPoint:CGPointMake(pX, bigY)],
        [NSValue valueWithCGPoint:CGPointMake(bigX, bigY)],
    ];
    
    return result;
}

- (void)reverseCrops
{
//    [self makeViewCenterInEditView];
    CGFloat pW = self.fragment.lowerRightX-self.fragment.lowerLeftX;
    
    CGFloat curW, curX, curY, minScale;
    if (_videoImageView.image) {
        curW = self.videoImageSize.width * pW;
        curX = self.videoImageSize.width * self.fragment.upperLeftX;
        curY = self.videoImageSize.height * self.fragment.upperLeftY;
        
        CGFloat minXScale = self.cropMaskRect.size.width/self.videoImageSize.width;
        CGFloat minYScale = self.cropMaskRect.size.height/self.videoImageSize.height;
        minScale = MAX(minXScale, minYScale);
    } else {
        curW = self.videoOriginalSize.width * pW;
        curX = self.videoOriginalSize.width * self.fragment.upperLeftX;
        curY = self.videoOriginalSize.height * self.fragment.upperLeftY;
        
        CGFloat minXScale = self.cropMaskRect.size.width/self.videoOriginalSize.width;
        CGFloat minYScale = self.cropMaskRect.size.height/self.videoOriginalSize.height;
        minScale = MAX(minXScale, minYScale);
    }
    
    CGFloat scale = self.cropMaskRect.size.width / curW;
    
    CGFloat offsetX = curX*scale - self.containerScrollView.contentInset.left;
    CGFloat offsetY = curY*scale - self.containerScrollView.contentInset.top;
    
    self.containerScrollView.minimumZoomScale = minScale;
    self.containerScrollView.zoomScale = scale;
    self.containerScrollView.contentOffset = CGPointMake(offsetX, offsetY);
    self.containerScrollView.maximumZoomScale = CGFLOAT_MAX;
}

- (void)makeViewCenterInEditView{
    CGFloat compareWidth = 1;
    CGFloat compareHeight = 1;
    if (_videoImageView.image) {
        compareWidth = self.videoImageSize.width;
        compareHeight = self.videoImageSize.height;
    } else {
        compareWidth = self.videoOriginalSize.width;
        compareHeight = self.videoOriginalSize.height;
    }
    CGFloat ratioOrigin = compareHeight / compareWidth;
    CGFloat ratioCrop = self.cropMaskRect.size.height / self.cropMaskRect.size.width;
    if (ratioOrigin <= 0 || ratioCrop <= 0){
        return ;
    }
    if ( ratioOrigin > ratioCrop) {
        self.fragment.upperLeftX = 0;
        self.fragment.upperLeftY = (ratioOrigin - ratioCrop)/ratioOrigin/2.0;
        self.fragment.upperRightX = 1;
        self.fragment.upperRightY = (ratioOrigin - ratioCrop)/ratioOrigin/2.0;
        self.fragment.lowerLeftX = 0;
        self.fragment.lowerLeftY = 1 - (ratioOrigin - ratioCrop)/ratioOrigin/2.0;
        self.fragment.lowerRightX = 1;
        self.fragment.lowerRightY = 1 - (ratioOrigin - ratioCrop)/ratioOrigin/2.0;
    } else {
        self.fragment.upperLeftX = (1/ratioOrigin - 1/ratioCrop)/2.0 * ratioOrigin;
        self.fragment.upperLeftY = 0;
        self.fragment.upperRightX = 1 - (1/ratioOrigin - 1/ratioCrop)/2.0 * ratioOrigin;
        self.fragment.upperRightY = 0;
        self.fragment.lowerLeftX = (1/ratioOrigin - 1/ratioCrop)/2.0 * ratioOrigin;
        self.fragment.lowerLeftY = 1;
        self.fragment.lowerRightX = 1 - (1/ratioOrigin - 1/ratioCrop)/2.0 * ratioOrigin;
        self.fragment.lowerRightY = 1;
    }
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (_videoImageView) {
        return _videoImageView;
    } else {
        return _videoPlayerView;
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    _videoPlayerControlView.enablePauseIcon = NO;
    [_cropMaskView animateForBlurEffect:NO animate:YES];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    _videoPlayerControlView.enablePauseIcon = YES;
    
    if (!scrollView.isDragging) {
        [_cropMaskView animateForBlurEffect:YES animate:YES];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _videoPlayerControlView.enablePauseIcon = NO;
    [_cropMaskView animateForBlurEffect:NO animate:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    _videoPlayerControlView.enablePauseIcon = YES;
    [self trackForCropImageAsset:self.publishModel];

    if (!decelerate) {
        [_cropMaskView animateForBlurEffect:YES animate:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_cropMaskView animateForBlurEffect:YES animate:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.didModified = YES;
}

#pragma mark - Notificaitons
- (void)p_appWillResignActive:(NSNotification *)notification
{
    [_videoPlayerView.player pause];
}

- (void)p_appDidBecomeActive:(NSNotification *)notification
{
    if (!self.isPauseByOthers && !self.isPauseByDisappear) {
        [self play];
    }
}
#pragma mark - Internal methods
- (void)didPlayTime:(CMTime)curTime
{
    if (CMTimeCompare(curTime, self.endTime) >= 0 && !self.isPauseByOthers) {
        [self.videoPlayerView.player seekToTime:self.startTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self.videoPlayerView.player play];
    }
}

- (void)p_handleContainerViewTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (_videoPlayerView.player.rate > 0.0 && _videoPlayerView.player.error == nil) {
        [self pause];
        [_videoPlayerControlView  showPauseWithAnimated:YES];
    } else {
        [self play];
        [_videoPlayerControlView hidePauseWithAnimated:YES];
    }
}

- (void)onChangeMaterialAction:(UIButton *)sender
{
    ACCBLOCK_INVOKE(self.changeMaterialCallback);
}

@end
