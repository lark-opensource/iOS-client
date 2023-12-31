//
//  AWEStudioCaptionsManager.m
//  Pods
//
//  Created by lixingdong on 2019/8/28.
//

#import "AWERepoCaptionModel.h"
#import "AWEStudioCaptionsManager.h"
#import "ACCAutoCaptionsTextStickerView.h"
#import "ACCAutoCaptionsTextStickerConfig.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import "AWERepoVideoInfoModel.h"

#import <TTVideoEditor/UIImage+Utils.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCCaptionsNetServiceProtocol.h>
#import <CameraClient/AWEStoryColorChooseView.h>
#import <CreationKitArch/ACCEditPageLayoutManager.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

static NSString *kCaptionFeedbackAppId = @"douyin_caption";

static CGFloat const kCaptionDefaultScale = 3.0;

#define kCaptionContainerRealHorizontalPadding (12 * kCaptionDefaultScale)
#define kCaptionContainerRealVerticalPadding   (6 * kCaptionDefaultScale)
#define kCaptionContainerRealBorderRadius      (6 * kCaptionDefaultScale)

#define ACCAutoCaptionTextViewWidth ((ACC_SCREEN_WIDTH - 48 - 74) * 2)

NS_INLINE BOOL p_isValidLineRect(CGRect rect) {
    return (!CGRectIsNull(rect) && !CGRectIsEmpty(rect) && CGRectGetWidth(rect) > ACC_FLOAT_ZERO);
}

@interface AWEStudioCaptionsManager()

// 用 weak 引用，否则在 NLE 模式下会存在内存泄漏
@property (nonatomic, weak) AWERepoVideoInfoModel *repoVideo;

@property (nonatomic, strong) AWERepoCaptionModel *repoCaption;
@property (nonatomic, strong) AWEStudioCaptionInfoModel *captionInfo;
@property (nonatomic, assign) NSInteger stickerEditId;
@property (nonatomic, assign) CGFloat containerHeight;

@property (nonatomic, copy) NSArray<AWEStudioCaptionModel *> *backupCaptions;
@property (nonatomic, strong) AWEInteractionStickerLocationModel *backupLocation;
@property (nonatomic, strong) AWEStudioCaptionInfoModel *backupCaptionInfo;
@property (nonatomic, strong) AWEStoryTextImageModel *backupTextInfo;

@property (nonatomic, assign) BOOL avoidDeleteCallback;

@property (nonatomic, strong) UIColor *fillColor;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) ACCStickerContainerView *stickerContainerView;

@property (nonatomic, assign) BOOL hasCaptionBeforeUpdateVideoData;

@end

@implementation AWEStudioCaptionsManager

@synthesize location = _location;
@synthesize colorIndex = _colorIndex;
@synthesize fontIndex = _fontIndex;

- (instancetype)initWithRepoCaptionModel:(AWERepoCaptionModel *)repoCaption
                               repoVideo:(AWERepoVideoInfoModel *)repoVideo
{
    self = [super init];
    if (self) {
        repoCaption.currentStatus = AWEStudioCaptionQueryStatusUpload;
        _captionStickerIdMaps = [NSMutableDictionary dictionary];
        _repoVideo = repoVideo;
        
        _captionInfo = repoCaption.captionInfo;
        _repoCaption = repoCaption;
        _fontColor = repoCaption.captionInfo.textInfoModel.fontColor;
        _fontModel = repoCaption.captionInfo.textInfoModel.fontModel;
        _colorIndex = repoCaption.captionInfo.textInfoModel.colorIndex;
        _fontIndex = repoCaption.captionInfo.textInfoModel.fontIndex;
        _textStyle = repoCaption.captionInfo.textInfoModel.textStyle;
        _location = repoCaption.captionInfo.location;
        // setCaptions will call updateLineRectArrayAndFrameForCaptionModel, use fontModel to caculate size
        self.captions = [[NSMutableArray alloc] initWithArray:repoCaption.captionInfo.captions copyItems:YES];
    }
    
    return self;
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)updateVideoDataBegin:(ACCEditVideoData *)videoData
                  updateType:(VEVideoDataUpdateType)updateType
                  multiTrack:(BOOL)multiTrack
{
    self.hasCaptionBeforeUpdateVideoData = NO;
    
    if (updateType != VEVideoDataUpdateAll || !multiTrack) {
        return;
    }
    
    self.hasCaptionBeforeUpdateVideoData = [videoData.infoStickers acc_any:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.acc_stickerType == ACCEditEmbeddedStickerTypeCaption;
    }];
}

- (void)updateVideoDataFinished:(ACCEditVideoData *)videoData
                     updateType:(VEVideoDataUpdateType)updateType
                     multiTrack:(BOOL)multiTrack
{
    if (updateType != VEVideoDataUpdateAll || !multiTrack) {
        return;
    }
    
    BOOL afterHasCaption = [videoData.infoStickers acc_any:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.acc_stickerType == ACCEditEmbeddedStickerTypeCaption;
    }];
    if (self.hasCaptionBeforeUpdateVideoData && !afterHasCaption) {
        // 这个模式下会清空自动字幕，需要重新走添加逻辑
        [self addCaptionsForEditService:self.editService
                          containerView:self.stickerContainerView];
    }
}

#pragma mark - 字幕添加、更新、删除操作

- (void)configCaptionImageBlockForEditService:(id<ACCEditServiceProtocol>)editService
                                containerView:(ACCStickerContainerView *)containerView
{
    self.repoCaption.deleted = NO;
    self.containerHeight = containerView.acc_height;
    
    // !!!IMPORTANT: 这里必须持有 self，否则在某些特殊情况中(例如首次安装)合成阶段 Component 已经被释放了，自动字幕会丢失
    // FIXME: 这里在首次安装的合成阶段会触发回调，所以这里必须持有 self，否则自动字幕会丢失
    @weakify(containerView);
    editService.sticker.captionStickerImageBlock = ^VEStickerImage * _Nullable(NSInteger stickerId) {
        @strongify(containerView);
        VEStickerImage *image = [self p_createCaptionStickerWithStickerId:stickerId];
        
        // 自动字幕-更新贴纸 bounds
        // 重置手势接收View的bounds
        self.stickerEditId = stickerId;
        dispatch_async(dispatch_get_main_queue(), ^{
            ACCAutoCaptionsTextStickerView *autoCaptionView =
            (ACCAutoCaptionsTextStickerView *)[containerView.allStickerViews btd_find:^BOOL(ACCStickerViewType  _Nonnull obj) {
                return [obj.config.typeId isEqualToString:ACCStickerTypeIdCaptions];
            }].contentView;

            if (autoCaptionView) {
                [autoCaptionView updateSize:CGSizeMake(image.imageSize.width / kCaptionDefaultScale,
                                                       image.imageSize.height / kCaptionDefaultScale)];
            }
        });
        return image;
    };
}

- (void)addCaptionsForEditService:(id<ACCEditServiceProtocol>)editService
                    containerView:(ACCStickerContainerView *)containerView
{
    self.editService = editService;
    self.stickerContainerView = containerView;
    
    [self configCaptionImageBlockForEditService:editService
                                  containerView:containerView];
    [self removeCaptionForEditService:editService
                        containerView:containerView];
    
    [self.captions enumerateObjectsUsingBlock:^(AWEStudioCaptionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj) {
            return;
        }
        
        NSInteger stickerId = [editService.sticker addSubtitleSticker];
        [editService.sticker setSticker:stickerId
                              startTime:obj.startTime / 1000.0
                               duration:(obj.endTime - obj.startTime) / 1000.0];
        
        [self.captionStickerIdMaps setObject:obj ?: [AWEStudioCaptionModel new] forKey:@(stickerId)];
    }];
    
    // 自动字幕-添加贴纸以及更新坐标
    self.stickerEditId = -1;
    [self p_updateVEStikcerLocationWithEditSticker:editService
                                          geometry:[self.location geometryModel]];
    [self p_updateVEStikcerScaleWithEditSticker:editService
                                       geometry:[self.location geometryModel]];
    [self p_applyAutoCaptionWithStickerContainer:containerView
                                     editService:editService];
}

- (void)removeCaptionForEditService:(id<ACCEditServiceProtocol>)editService
                      containerView:(ACCStickerContainerView *)containerView
{
    [self p_removeCaptionWithEditService:editService
                           containerView:containerView];
}

- (void)updateCaptionLineRectForAll
{
    // 自动字幕-更新透明度
    AWEStoryTextImageModel *textInfo = self.captionInfo.textInfoModel;
    [self.captions enumerateObjectsUsingBlock:^(AWEStudioCaptionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        textInfo.content = obj.text;
        [self p_updateLineRectArrayAndFrameForCaptionModel:obj];
    }];
}

- (void)addCaptionsForPublishTaskWithEditService:(id<ACCEditServiceProtocol>)editService
{
    self.editService = editService;
    editService.sticker.captionStickerImageBlock = ^VEStickerImage * _Nullable(NSInteger stickerId) {
        VEStickerImage *image = [self p_createCaptionStickerWithStickerId:stickerId];
        return image;
    };
    
    [self removeCaptionForEditService:editService
                        containerView:self.stickerContainerView];
    
    [self.captionStickerIdMaps removeAllObjects];
    
    [self.captions enumerateObjectsUsingBlock:^(AWEStudioCaptionModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj) {
            return;
        }
        
        NSInteger stickerId = [editService.sticker addSubtitleSticker];
        [editService.sticker setSticker:stickerId
                              startTime:obj.startTime / 1000.0
                               duration:(obj.endTime - obj.startTime) / 1000.0];
        
        [self.captionStickerIdMaps setObject:obj ?: [AWEStudioCaptionModel new] forKey:@(stickerId)];
    }];
    self.stickerEditId = -1;
    [self p_updateVEStikcerLocationWithEditSticker:editService
                                          geometry:[self.location geometryModel]];
    [self p_updateVEStikcerScaleWithEditSticker:editService
                                       geometry:[self.location geometryModel]];
}


// 主线程保存字幕lineRect 及 frame信息
- (void)p_updateLineRectArrayAndFrameForCaptionModel:(AWEStudioCaptionModel *)model
{
    AWEStoryTextImageModel *textInfoModel = self.captionInfo.textInfoModel;
    textInfoModel.content = model.text;
    
    AWEStoryFontModel *fontModel = textInfoModel.fontModel;
    AWEStoryColor *fontColor = textInfoModel.fontColor;
    
    NSMutableParagraphStyle *alignment = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
    alignment.alignment = NSTextAlignmentCenter;
    
    UIFont *font = [self p_fontWithFontModel:textInfoModel.fontModel size:textInfoModel.fontSize * kCaptionDefaultScale];
    
    if (fontModel.hasShadeColor) {
        // 霓虹字体
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 10;
        shadow.shadowColor = textInfoModel.fontColor.color;
        shadow.shadowOffset = CGSizeMake(0, 0);
        
        NSDictionary *params = @{NSShadowAttributeName : shadow,
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSFontAttributeName : font,
                                 NSParagraphStyleAttributeName : alignment,
                                 NSBaselineOffsetAttributeName: @(-1.5f),
                                 };
        
        NSString *text = model.text;
        CGSize size = [self p_textSizeWithText:text attributes:params limitWidth:ACCAutoCaptionTextViewWidth * kCaptionDefaultScale lineRectStringArray:nil];
        CGRect rect = CGRectMake(0, 0, size.width + kCaptionContainerRealHorizontalPadding * 2, size.height + kCaptionContainerRealVerticalPadding * 2);
        model.rect = NSStringFromCGRect(rect);
        
        return;
    } else {
        // 带背景字体
        AWEStoryTextStyle style = textInfoModel.textStyle;
        UIColor *textColor = fontColor.color ?: [UIColor whiteColor];
        if (style == AWEStoryTextStyleNo || style == AWEStoryTextStyleStroke) {
            textColor = fontColor.color ?: [UIColor whiteColor];
            self.fillColor = [UIColor clearColor];
            
        } else {
            if (CGColorEqualToColor(fontColor.color.CGColor, [ACCUIColorFromRGBA(0xffffff,1.f) CGColor])) {
                if (style == AWEStoryTextStyleBackground) {
                    textColor = [UIColor blackColor];
                } else {
                    textColor = [UIColor whiteColor];
                }
            } else {
                textColor = [UIColor whiteColor];
            }
            
            if (style == AWEStoryTextStyleBackground) {
                self.fillColor = fontColor.color;
            } else {
                self.fillColor = [fontColor.color colorWithAlphaComponent:0.5];
            }
        }
        
        NSDictionary *params = @{
                                 NSForegroundColorAttributeName : textColor,
                                 NSParagraphStyleAttributeName : alignment,
                                 NSFontAttributeName : font,
                                 NSBaselineOffsetAttributeName: @(-1.5f),
                                 };
        
        NSString *text = textInfoModel.content;
        NSMutableArray<NSString *> *lineRectStringArray = [NSMutableArray array];
        CGSize size = [self p_textSizeWithText:text attributes:params limitWidth:ACCAutoCaptionTextViewWidth * kCaptionDefaultScale lineRectStringArray:lineRectStringArray];
        
        CGRect rect = CGRectMake(0, 0, size.width + kCaptionContainerRealHorizontalPadding * 2, size.height + kCaptionContainerRealVerticalPadding * 2);
        
        model.rect = NSStringFromCGRect(rect);
        model.lineRectArray = [lineRectStringArray copy];
    }
}

- (CGSize)p_textSizeWithText:(NSString *)text attributes:(NSDictionary *)attributes limitWidth:(CGFloat)width lineRectStringArray:(NSMutableArray<NSString *> *)lineRectStringArray
{
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:text attributes:attributes];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    layoutManager.usesFontLeading = NO;
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width, MAXFLOAT)];
    textContainer.lineFragmentPadding = 0;
    [layoutManager addTextContainer:textContainer];
    [storage addLayoutManager:layoutManager];
    
    CGSize size = [layoutManager usedRectForTextContainer:textContainer].size;
    textContainer.size = size;

    if (lineRectStringArray) {
        NSMutableArray<NSValue *> *lineRectValueArray = [@[] mutableCopy];
        
        NSRange range = NSMakeRange(0, 0);
        CGRect lineRect = [layoutManager lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:&range];
        
        if (range.length != 0 && p_isValidLineRect(lineRect)) {
            [lineRectValueArray addObject:[NSValue valueWithCGRect:lineRect]];
        }
        while (range.location + range.length < text.length) {
            lineRect = [layoutManager lineFragmentUsedRectForGlyphAtIndex:(range.location + range.length) effectiveRange:&range];
            if (range.length != 0 && p_isValidLineRect(lineRect)) {
                [lineRectValueArray addObject:[NSValue valueWithCGRect:lineRect]];
            }
        }
        
        int i = 0;
        while (i < lineRectValueArray.count) {

            BOOL isFirstLine = (i == 0), isLastLine = (i == lineRectValueArray.count-1);
            CGFloat x = lineRectValueArray[i].CGRectValue.origin.x;
            CGFloat y = lineRectValueArray[i].CGRectValue.origin.y ;
            CGFloat width = lineRectValueArray[i].CGRectValue.size.width + kCaptionContainerRealHorizontalPadding * 2;
            CGFloat height = lineRectValueArray[i].CGRectValue.size.height;
            /// Calculate the correct 'draw size' for each line.
            /// @todo The best solution is to fit the padding of the container，not line size.
            if(isFirstLine) {
                height += kCaptionContainerRealVerticalPadding;
            }else {
                y += kCaptionContainerRealVerticalPadding;
            }
            if(isLastLine) {
                height += kCaptionContainerRealVerticalPadding;
            }
            CGRect lineRect = CGRectMake(x, y, width, height);
            [lineRectStringArray addObject:NSStringFromCGRect(lineRect)];
            
            i++;
        }
    }
    
    return size;
}

#pragma mark - New Container

- (void)p_applyAutoCaptionWithStickerContainer:(ACCStickerContainerView *)stickerContainer
                                   editService:(id<ACCEditServiceProtocol>)editService
{
    if (!stickerContainer || !editService) {
        return;
    }
    
    ACCAutoCaptionsTextStickerConfig *config = [[ACCAutoCaptionsTextStickerConfig alloc] init];
    config.typeId = ACCStickerTypeIdCaptions;
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryLow);
    config.geometryModel = [self.location geometryModel];
    config.timeRangeModel = [self p_totalTimeRangeWithEditService:editService];
    config.changeAnchorForRotateAndScale = NO;
    config.showSelectedHint = NO;
    
    ACCAutoCaptionsTextStickerView *contentView = [[ACCAutoCaptionsTextStickerView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    contentView.center = editService.mediaContainerView.center;
    
    @weakify(self);
    contentView.transparentChanged = ^(BOOL transparent) {
        @strongify(self);
        NSArray *stickerIds = self.captionStickerIdMaps.allKeys;
        [editService.sticker setStickerAlphas:stickerIds alpha:(transparent? 0.34: 1.0) above:!transparent];
    };
    
    config.gestureCanStartCallback =
    ^BOOL(__kindof ACCBaseStickerView * _Nonnull wrapperView, UIGestureRecognizer * _Nonnull gesture) {
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            [editService.preview setHighFrameRateRender:YES];
        }
        return ![gesture isKindOfClass:UIRotationGestureRecognizer.class];
    };
    
    config.gestureEndCallback =
    ^(__kindof ACCBaseStickerView * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            [editService.preview setHighFrameRateRender:NO];
        }
    };
    
    config.externalHandlePanGestureAction =
    ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGPoint point) {
        @strongify(self);
        [self p_updateVEStikcerLocationWithEditSticker:editService
                                              geometry:theView.stickerGeometry];
    };
    
    config.externalHandlePinchGestureeAction = ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGFloat scale) {
        @strongify(self);
        ACCAutoCaptionsTextStickerView *contentView = (ACCAutoCaptionsTextStickerView *)theView.contentView;
        contentView.transparent = NO;
        
        [self p_updateVEStikcerScaleWithEditSticker:editService
                                           geometry:theView.stickerGeometry];
    };
    
    config.willDeleteCallback = ^{
        @strongify(self);
        if (self.avoidDeleteCallback) {
            return;
        }
        
        !self.deleteStickerAction ?: self.deleteStickerAction();
    };
    
    config.deleteBlock = ^{
        @strongify(self);
        !self.deleteStickerAction ?: self.deleteStickerAction();
    };
    
    config.editBlock = ^{
        @strongify(self);
        !self.editStickerAction ?: self.editStickerAction();
    };
    
    ACCStickerViewType wrapperView = [stickerContainer addStickerView:contentView config:config];
    wrapperView.stickerGeometry.preferredRatio = NO;
}

- (void)p_removeCaptionWithEditService:(id<ACCEditServiceProtocol>)editService
                         containerView:(ACCStickerContainerView *)containerView
{
    self.avoidDeleteCallback = YES;
    [[containerView.allStickerViews btd_filter:^BOOL(ACCStickerViewType  _Nonnull obj) {
        return [obj.config.typeId isEqualToString:ACCStickerTypeIdCaptions];
    }] btd_forEach:^(ACCStickerViewType  _Nonnull obj) {
        [containerView removeStickerView:obj];
    }];
    self.avoidDeleteCallback = NO;
    
    [[self.editService.sticker infoStickers] enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.acc_stickerType == ACCEditEmbeddedStickerTypeCaption) {
            [self.editService.sticker removeInfoSticker:obj.stickerId];
        }
    }];
    
    [self.captionStickerIdMaps removeAllObjects];
}

- (void)p_updateVEStikcerLocationWithEditSticker:(id<ACCEditServiceProtocol>)editService
                                        geometry:(ACCStickerGeometryModel *)geometry
{
    CGFloat offsetX = [geometry.x floatValue];
    CGFloat offsetY = -[geometry.y floatValue];
    CGFloat angle = [geometry.rotation floatValue];
    
    offsetX = ACCRTL().isRTL ? -offsetX : offsetX;
    
    NSArray *stickerIds = self.captionStickerIdMaps.allKeys;
    [editService.sticker setStickersAbove:stickerIds offsetX:offsetX offsetY:offsetY angle:angle scale:1.0];
    
    ACCStickerTimeRangeModel *timeRangeModel = [self p_totalTimeRangeWithEditService:editService];
    self.location = [[AWEInteractionStickerLocationModel alloc]
                     initWithGeometryModel:geometry
                     andTimeRangeModel:timeRangeModel];
}

- (void)p_updateVEStikcerScaleWithEditSticker:(id<ACCEditServiceProtocol>)editService
                                     geometry:(ACCStickerGeometryModel *)geometry
{
    CGFloat absoluteScale = geometry.scale.floatValue;
    NSArray *stickerIds = self.captionStickerIdMaps.allKeys;
    [editService.sticker setStickersScale:stickerIds scale:absoluteScale/kCaptionDefaultScale];
    
    ACCStickerTimeRangeModel *timeRangeModel = [self p_totalTimeRangeWithEditService:editService];
    self.location = [[AWEInteractionStickerLocationModel alloc]
                     initWithGeometryModel:geometry
                     andTimeRangeModel:timeRangeModel];
}

- (ACCStickerTimeRangeModel *)p_totalTimeRangeWithEditService:(id<ACCEditServiceProtocol>)editService
{
    ACCStickerTimeRangeModel *timeRangeModel = [[ACCStickerTimeRangeModel alloc] init];
    timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
    NSString *endTime = [NSString stringWithFormat:@"%.4f", self.repoVideo.video.totalVideoDuration * 1000];
    timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
    timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    return timeRangeModel;
}

#pragma mark - VESDK imamgeBlock

- (VEStickerImage *)p_createCaptionStickerWithStickerId:(NSInteger)stickerId
{
    @autoreleasepool {
        AWEStudioCaptionModel *model = ACCDynamicCast([self.captionStickerIdMaps objectForKey:@(stickerId)],
                                                      AWEStudioCaptionModel);
        if (!model) {
            return nil;
        }
        
        // 下面两个操作有可能在后台执行，所以里面不能有UI相关操作
        UIImage *image = [self p_captionImageWithCaptionModel:model]; // 获取字幕image
        NSData *imageData = [image rawDataPixelFormatRGBA8888];     // image转bitmap
        VEStickerImage *captionImage = [[VEStickerImage alloc] initWithData:imageData imageSize:CGSizeMake(floor(image.size.width), floor(image.size.height))];
        return captionImage;
    }
}

#pragma mark - 绘制字幕

- (UIImage *)p_captionImageWithCaptionModel:(AWEStudioCaptionModel *)model
{
    @autoreleasepool {
        AWEStoryTextImageModel *textInfoModel = self.captionInfo.textInfoModel;
        AWEStoryFontModel *fontModel = textInfoModel.fontModel;
        AWEStoryColor *fontColor = textInfoModel.fontColor ? : [AWEStoryColorChooseView storyColors].firstObject;
        AWEStoryTextStyle style = textInfoModel.textStyle;
        UIFont *font = [self p_fontWithFontModel:textInfoModel.fontModel size:textInfoModel.fontSize * kCaptionDefaultScale];
        NSMutableParagraphStyle *alignment = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        alignment.alignment = NSTextAlignmentCenter;
        
        if (fontModel.hasShadeColor) {
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowBlurRadius = 10;
            shadow.shadowColor = textInfoModel.fontColor.color;
            shadow.shadowOffset = CGSizeMake(0, 0);
            
            NSDictionary *params = @{NSShadowAttributeName : shadow,
                                     NSForegroundColorAttributeName : [UIColor whiteColor],
                                     NSFontAttributeName : font,
                                     NSParagraphStyleAttributeName : alignment,
                                     NSBaselineOffsetAttributeName: @(-1.5f),
                                     };
            
            NSString *text = model.text;
            CGRect rect = CGRectFromString(model.rect);
            
            UIGraphicsBeginImageContextWithOptions(rect.size, NO, ACC_SCREEN_SCALE);

            [text drawInRect:rect withAttributes:params];

            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            return image;
        } else {
            UIColor *textColor = fontColor.color ?: [UIColor whiteColor];
            
            if (style == AWEStoryTextStyleNo || style == AWEStoryTextStyleStroke) {
                textColor = fontColor.color ?: [UIColor whiteColor];
                self.fillColor = [UIColor clearColor];
                
            } else {
                if (CGColorEqualToColor(fontColor.color.CGColor, [ACCUIColorFromRGBA(0xffffff,1.f) CGColor])) {
                    if (style == AWEStoryTextStyleBackground) {
                        textColor = [UIColor blackColor];
                    } else {
                        textColor = [UIColor whiteColor];
                    }
                } else {
                    textColor = [UIColor whiteColor];
                }
                
                if (style == AWEStoryTextStyleBackground) {
                    self.fillColor = fontColor.color;
                } else {
                    self.fillColor = [fontColor.color colorWithAlphaComponent:0.5];
                }
            }
            
            ACCEditPageStrokeConfig *strokeConfig = nil;
            if ((!fontModel || fontModel.supportStroke) && style == AWEStoryTextStyleStroke && fontColor.borderColor) {
                strokeConfig = [ACCEditPageStrokeConfig strokeWithWidth:2 * kCaptionDefaultScale color:fontColor.borderColor lineJoin:kCGLineJoinRound];
            }
            
            NSDictionary *params = @{
                                     NSForegroundColorAttributeName : textColor,
                                     NSParagraphStyleAttributeName : alignment,
                                     NSFontAttributeName : font,
                                     NSBaselineOffsetAttributeName: @(-1.5f),
                                     };
            
            NSString *text = model.text;
            CGRect rect = CGRectFromString(model.rect);
            
            UIImage *image = [self p_captionImageWithlineRectInfo:model.lineRectArray text:text attributes:params inRect:rect stroke:strokeConfig];
            
            return image;
        }
    }
}

- (UIImage *)p_captionImageWithlineRectInfo:(NSArray *)lineRectArray text:(NSString *)text attributes:(NSDictionary *)attributes inRect:(CGRect)rect stroke:(ACCEditPageStrokeConfig *)strokeConfig
{
    @autoreleasepool {
        NSMutableArray *lineRects = [NSMutableArray array];
        [lineRectArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect rect = CGRectFromString(obj);
            [lineRects addObject:[NSValue valueWithCGRect:rect]];
        }];
        
        UIBezierPath *path = [self p_drawCaptionPathWithLineRectArray:lineRects fillColor:self.fillColor];
        
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, ACC_SCREEN_SCALE);
        
        // 绘制背景
        if (path) {
            [self.fillColor set];
            [path fill];
        }
        
        if (!text) {
            text = @"";
            AWELogToolError(AWELogToolTagEdit, @"CaptionManager, text is nil, %@", [self.captionInfo dictionaryValue]);
        }
        
        NSTextStorage *storage = [[NSTextStorage alloc] initWithString:text attributes:attributes];
        ACCEditPageLayoutManager *layoutManager = [[ACCEditPageLayoutManager alloc] init];
        layoutManager.strokeConfig = strokeConfig;
        layoutManager.usesFontLeading = NO;
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(rect.size.width - 2 * kCaptionContainerRealHorizontalPadding, rect.size.height - 2 * kCaptionContainerRealVerticalPadding)];
        textContainer.lineFragmentPadding = 0;
        [layoutManager addTextContainer:textContainer];
        [storage addLayoutManager:layoutManager];
        
        [layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, storage.length) atPoint:CGPointMake(kCaptionContainerRealHorizontalPadding, kCaptionContainerRealVerticalPadding)];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}

// 绘制字幕背景path
- (UIBezierPath *)p_drawCaptionPathWithLineRectArray:(NSArray<NSValue *> *)array fillColor:(UIColor *)fillColor
{
    if (ACC_isEmptyArray(array)) {
        return nil;
    }
    
    NSMutableArray<NSValue *> *lineRectArray = [array mutableCopy];
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    if (lineRectArray.count == 1) {
        CGRect currentLineRect = lineRectArray[0].CGRectValue;
        CGPoint topMidPoint = [self p_topMidPointWithRect:currentLineRect isBoundaryLine:YES];
        [path moveToPoint:topMidPoint];

        CGPoint leftTop = [self p_leftTopWithRect_up:currentLineRect isBoundaryLine:YES];
        CGPoint leftTopCenter = CGPointMake(leftTop.x + kCaptionContainerRealBorderRadius , leftTop.y + kCaptionContainerRealBorderRadius);
        [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
        [path addArcWithCenter:leftTopCenter radius:kCaptionContainerRealBorderRadius startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];

        CGPoint leftBottomPoint = [self p_leftBottomWithRect_down:currentLineRect isBoundaryLine:YES];
        CGPoint leftBottomCenter = CGPointMake(leftBottomPoint.x + kCaptionContainerRealBorderRadius, leftBottomPoint.y - kCaptionContainerRealBorderRadius);
        [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
        [path addArcWithCenter:leftBottomCenter radius:kCaptionContainerRealBorderRadius startAngle:M_PI endAngle:M_PI_2 clockwise:NO];

        CGPoint bottomMid = [self p_bottomMidPointWithRect:currentLineRect isBoundaryLine:YES];
        [path addLineToPoint:bottomMid];
    } else if (lineRectArray.count > 1) {
        int i = 0;
        while (i < lineRectArray.count - 1) {
            CGRect currentLineRect = lineRectArray[i].CGRectValue;
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            if (fabs(currentLineRect.size.width - nextLineRect.size.width) <= (4 * kCaptionContainerRealBorderRadius + 1)) {
                //如果两行之差小于2 * kCaptionContainerRealBorderRadius
                if (currentLineRect.size.width > nextLineRect.size.width) {
                    lineRectArray[i] = @(CGRectMake(currentLineRect.origin.x, currentLineRect.origin.y, currentLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                } else {
                    lineRectArray[i] = @(CGRectMake(nextLineRect.origin.x, currentLineRect.origin.y, nextLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                }
                [lineRectArray removeObjectAtIndex:(i + 1)];
            } else {
                i ++;
            }
        }

        path = [self p_drawAlignmentCenterLineRectArray:lineRectArray];
    }

    //先移动到原点，然后做翻转，然后再移动到指定位置
    UIBezierPath *reversingPath = path.bezierPathByReversingPath;
    CGRect boxRect = CGPathGetPathBoundingBox(reversingPath.CGPath);
    [reversingPath applyTransform:CGAffineTransformMakeTranslation(- CGRectGetMidX(boxRect), - CGRectGetMidY(boxRect))];
    [reversingPath applyTransform:CGAffineTransformMakeScale(-1, 1)];
    [reversingPath applyTransform:CGAffineTransformMakeTranslation(CGRectGetWidth(boxRect) + CGRectGetMidX(boxRect), CGRectGetMidY(boxRect))];
    [path appendPath:reversingPath];

    return path;
}

- (UIBezierPath *)p_drawAlignmentCenterLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint topMidPoint = [self p_topMidPointWithRect:firstLineRect isBoundaryLine:YES];
    [path moveToPoint:topMidPoint];
    
    CGPoint leftTop = [self p_leftTopWithRect_up:firstLineRect isBoundaryLine:YES];
    CGPoint leftTopCenter = [self p_leftTopCenterWithRect_up:firstLineRect isBoundaryLine:YES];
    [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    [path addArcWithCenter:leftTopCenter radius:kCaptionContainerRealBorderRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            //当前行是中间行
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            CGPoint nextLineLeftTopPoint;
            CGPoint nextLineLeftTopCenter;
            if (nextLineRect.origin.x > currentLineRect.origin.x) {
                leftBottomPoint = [self p_leftBottomWithRect_down:currentLineRect isBoundaryLine:NO];
                leftBottomCenter = [self p_leftBottomCenterWithRect_down:currentLineRect isBoundaryLine:NO];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kCaptionContainerRealBorderRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineLeftTopPoint = [self p_leftTopWithRect_down:nextLineRect isBoundaryLine:NO];
                nextLineLeftTopCenter = [self p_leftTopCenterWithRect_down:nextLineRect isBoundaryLine:NO];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kCaptionContainerRealBorderRadius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            } else {
                leftBottomPoint = [self p_leftBottomWithRect_up:currentLineRect isBoundaryLine:NO];
                leftBottomCenter = [self p_leftBottomCenterWithRect_up:currentLineRect isBoundaryLine:NO];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kCaptionContainerRealBorderRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineLeftTopPoint = [self p_leftTopWithRect_up:nextLineRect isBoundaryLine:NO];
                nextLineLeftTopCenter = [self p_leftTopCenterWithRect_up:nextLineRect isBoundaryLine:NO];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kCaptionContainerRealBorderRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            }
        } else {
            //当前行是最后一行
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            leftBottomPoint = [self p_leftBottomWithRect_down:currentLineRect isBoundaryLine:YES];
            leftBottomCenter = [self p_leftBottomCenterWithRect_down:currentLineRect isBoundaryLine:YES];
            [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
            [path addArcWithCenter:leftBottomCenter radius:kCaptionContainerRealBorderRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
            
            CGPoint bottomMidPoint = CGPointMake(CGRectGetMidX(currentLineRect), CGRectGetMaxY(currentLineRect));
            [path addLineToPoint:CGPointMake(topMidPoint.x, bottomMidPoint.y)];
        }
    }
    
    return path;
}

// 节点信息
// isBoundaryLine : first or last line
- (CGPoint)p_leftTopWithRect_up:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(rect.origin.x , rect.origin.y - (isBoundaryLine ? 0: kCaptionContainerRealVerticalPadding));
}

- (CGPoint)p_leftTopCenterWithRect_up:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    CGPoint leftTop = [self p_leftTopWithRect_up:rect isBoundaryLine:isBoundaryLine];
    return CGPointMake(leftTop.x + kCaptionContainerRealBorderRadius , leftTop.y + kCaptionContainerRealBorderRadius);
}

- (CGPoint)p_leftTopWithRect_down:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(rect.origin.x , rect.origin.y + (isBoundaryLine ? 0: kCaptionContainerRealVerticalPadding));
}

- (CGPoint)p_leftTopCenterWithRect_down:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    CGPoint leftTop = [self p_leftTopWithRect_down:rect isBoundaryLine:isBoundaryLine];
    return CGPointMake(leftTop.x - kCaptionContainerRealBorderRadius, leftTop.y + kCaptionContainerRealBorderRadius);
}

- (CGPoint)p_leftBottomWithRect_up:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(rect.origin.x , rect.origin.y + rect.size.height - (isBoundaryLine? 0: kCaptionContainerRealVerticalPadding));
}

- (CGPoint)p_leftBottomCenterWithRect_up:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    CGPoint leftBottomPoint = [self p_leftBottomWithRect_up:rect isBoundaryLine:isBoundaryLine];
    return CGPointMake(leftBottomPoint.x - kCaptionContainerRealBorderRadius, leftBottomPoint.y - kCaptionContainerRealBorderRadius);
}

- (CGPoint)p_leftBottomWithRect_down:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(rect.origin.x, rect.origin.y + rect.size.height + (isBoundaryLine? 0: kCaptionContainerRealVerticalPadding));
}

- (CGPoint)p_leftBottomCenterWithRect_down:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    CGPoint leftBottomPoint = [self p_leftBottomWithRect_down:rect isBoundaryLine:isBoundaryLine];
    return CGPointMake(leftBottomPoint.x + kCaptionContainerRealBorderRadius, leftBottomPoint.y - kCaptionContainerRealBorderRadius);
}

- (CGPoint)p_topMidPointWithRect:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(CGRectGetMidX(rect), rect.origin.y - (isBoundaryLine? 0: kCaptionContainerRealVerticalPadding));
}

- (CGPoint)p_bottomMidPointWithRect:(CGRect)rect isBoundaryLine:(BOOL)isBoundaryLine
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect) + (isBoundaryLine? 0: kCaptionContainerRealVerticalPadding));
}

#pragma mark - Utils

- (UIFont *)p_fontWithFontModel:(AWEStoryFontModel *)fontModel size:(CGFloat)size
{
    UIFont *font = [ACCFont() systemFontOfSize:size weight:ACCFontWeightHeavy];
    if (fontModel) {
        font = [ACCCustomFont() fontWithModel:fontModel size:size];
    }
    
    return font;
}

#pragma mark - 备份/恢复

- (void)resetDeleteState
{
    self.repoCaption.deleted = NO;
}

- (void)backupTextStyle
{
    self.backupTextInfo.colorIndex = self.colorIndex;
    self.backupTextInfo.fontColor = self.fontColor;
    self.backupTextInfo.fontIndex = self.fontIndex;
    self.backupTextInfo.fontModel = self.fontModel;
    self.backupTextInfo.textStyle = self.textStyle;
}

- (void)restoreTextStyle
{
    self.colorIndex = self.backupTextInfo.colorIndex;
    self.fontColor = self.backupTextInfo.fontColor;
    self.fontIndex = self.backupTextInfo.fontIndex;
    self.fontModel = self.backupTextInfo.fontModel;
    self.textStyle = self.backupTextInfo.textStyle;
}

- (void)backupCaptionData
{
    self.backupCaptionInfo = [self.captionInfo copy];
    self.backupCaptions = [[NSArray alloc] initWithArray:self.captions copyItems:YES]; // deep copy
    self.backupLocation = [self.location copy];
    
    self.backupCaptionInfo.textInfoModel.fontColor = self.fontColor;
    self.backupCaptionInfo.textInfoModel.fontModel = self.fontModel;
    self.backupCaptionInfo.textInfoModel.colorIndex = self.colorIndex;
    self.backupCaptionInfo.textInfoModel.fontIndex = self.fontIndex;
    self.backupCaptionInfo.textInfoModel.textStyle = self.textStyle;
}

- (void)restoreCaptionData
{
    self.captionInfo = [self.backupCaptionInfo copy];
    self.captions = [[NSMutableArray alloc] initWithArray:self.backupCaptions copyItems:YES];//[self.backupcaptions mutableCopy];
    self.location = self.backupLocation;
    
    self.fontColor = self.backupCaptionInfo.textInfoModel.fontColor;
    self.fontModel = self.backupCaptionInfo.textInfoModel.fontModel;
    self.colorIndex = self.backupCaptionInfo.textInfoModel.colorIndex ?: [NSIndexPath indexPathForRow:0 inSection:0];
    self.fontIndex = self.backupCaptionInfo.textInfoModel.fontIndex ?: [NSIndexPath indexPathForRow:0 inSection:0];
    self.textStyle = self.backupCaptionInfo.textInfoModel.textStyle;
}

- (void)deleteCaption
{
    self.captions = nil;
    self.backupCaptions = nil;
    self.captionInfo = nil;
    self.backupCaptionInfo = nil;
    self.repoCaption.tosKey = nil;
    
    self.fontColor = nil;
    self.fontModel = nil;
    self.colorIndex = nil;
    self.fontIndex = nil;
    self.textStyle = AWEStoryTextStyleNo;
    self.location = nil;
    self.repoCaption.deleted = YES;
    
    self.repoCaption.currentStatus = AWEStudioCaptionQueryStatusUpload;
}

#pragma mark - Setter / Getter

- (AWEInteractionStickerLocationModel *)p_originLocation
{
    CGFloat y = 0.2 * self.containerHeight;
    AWEInteractionStickerLocationModel *location = [AWEInteractionStickerLocationModel new];
    location.scale = [NSDecimalNumber decimalNumberWithString:@"1.0"];
    location.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", y]];
    return location;
}

- (NSMutableArray<AWEStudioCaptionModel *> *)captions
{
    return self.repoCaption.captions;
}

- (void)setCaptions:(NSMutableArray<AWEStudioCaptionModel *> *)captions
{
    self.repoCaption.captions = captions;
    self.captionInfo.captions = captions;
    [self updateCaptionLineRectForAll];
}

- (void)setLocation:(AWEInteractionStickerLocationModel *)location
{
    if (location == nil) {
        location = [self p_originLocation];
    }
    _location = location;
    self.captionInfo.location = location;
}

- (void)setFontColor:(AWEStoryColor *)fontColor
{
    _fontColor = fontColor;
    self.captionInfo.textInfoModel.fontColor = fontColor;
}

- (void)setFontModel:(AWEStoryFontModel *)fontModel
{
    _fontModel = fontModel;
    self.captionInfo.textInfoModel.fontModel = fontModel;
}

- (void)setFontIndex:(NSIndexPath *)fontIndex
{
    _fontIndex = fontIndex;
    self.captionInfo.textInfoModel.fontIndex = fontIndex;
}

- (void)setColorIndex:(NSIndexPath *)colorIndex
{
    _colorIndex = colorIndex;
    self.captionInfo.textInfoModel.colorIndex = colorIndex;
}

- (void)setTextStyle:(AWEStoryTextStyle)textStyle
{
    _textStyle = textStyle;
    self.captionInfo.textInfoModel.textStyle = textStyle;
}

- (AWEInteractionStickerLocationModel *)location
{
    if (!_location) {
        _location = [self p_originLocation];
    }
    
    return _location;
}

- (NSIndexPath *)fontIndex
{
    if (!_fontIndex) {
        _fontIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    return _fontIndex;
}

- (NSIndexPath *)colorIndex
{
    if (!_colorIndex) {
        _colorIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    return _colorIndex;
}

- (AWEStudioCaptionInfoModel *)captionInfo
{
    if (!_captionInfo) {
        _captionInfo = [AWEStudioCaptionInfoModel new];
    }
    
    return _captionInfo;
}

- (AWEStudioCaptionInfoModel *)backupCaptionInfo
{
    if (!_backupCaptionInfo) {
        _backupCaptionInfo = [AWEStudioCaptionInfoModel new];
    }
    
    return _backupCaptionInfo;
}

- (AWEStoryTextImageModel *)backupTextInfo
{
    if (!_backupTextInfo) {
        _backupTextInfo = [AWEStoryTextImageModel new];
    }
    
    return _backupTextInfo;
}

- (void)setNeedUploadAudio
{
    [self deleteCaption];
    self.repoCaption.deleted = NO;
}

@end
