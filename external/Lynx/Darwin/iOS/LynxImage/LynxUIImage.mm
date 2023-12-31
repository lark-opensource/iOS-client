// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxUIImage.h"
#import "LynxBlurImageProcessor.h"
#import "LynxComponentRegistry.h"
#import "LynxConvertUtils.h"
#import "LynxEnv.h"
#import "LynxErrorCode.h"
#import "LynxImageBlurUtils.h"
#import "LynxImageLoader.h"
#import "LynxImageProcessor.h"
#import "LynxMeasureDelegate.h"
#import "LynxMemoryListener.h"
#import "LynxNinePatchImageProcessor.h"
#import "LynxPropsProcessor.h"
#import "LynxService.h"
#import "LynxServiceTrailProtocol.h"
#import "LynxShadowNodeOwner.h"
#import "LynxUI+Internal.h"
#import "LynxUIUnitUtils.h"
#import "LynxUnitUtils.h"

#import "LynxBackgroundUtils.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxView+Internal.h"

#import "LynxService.h"
#import "LynxServiceImageProtocol.h"
#import "LynxVersion.h"

typedef NS_ENUM(NSInteger, LynxResizeMode) {
  LynxResizeModeCover = UIViewContentModeScaleAspectFill,
  LynxResizeModeContain = UIViewContentModeScaleAspectFit,
  LynxResizeModeScaleToFill = UIViewContentModeScaleToFill,
  LynxResizeModeCenter = UIViewContentModeCenter
};

#pragma mark LynxURL

@implementation LynxURL

- (void)updatePreviousUrl {
  _preUrl = _url;
}

- (BOOL)isPreviousUrl {
  return [_url.absoluteString isEqualToString:_preUrl.absoluteString];
}

- (void)initResourceInformation {
  if (!_resourceInfo) {
    _resourceInfo = [NSMutableDictionary dictionary];
  }
  _resourceInfo[@"res_src"] = _url.absoluteString ?: @"";
  _resourceInfo[@"res_scene"] = @"lynx_image";
}
@end

@interface LynxUIImageDrawParameter : NSObject

@property(nonatomic) UIImage* image;
@property(nonatomic) UIEdgeInsets borderWidth;
@property(nonatomic) LynxBorderRadii borderRadius;
@property(nonatomic) UIEdgeInsets padding;
@property(nonatomic) CGRect frame;
@property(nonatomic, assign) UIViewContentMode resizeMode;

@end

@implementation LynxUIImageDrawParameter

@end

/**
 Use to process image into image with border radius.
 */
@interface LynxBorderRadiusImageProcessor : NSObject <LynxImageProcessor>

- (instancetype)initWithDrawParameter:(LynxUIImageDrawParameter*)param;

@property(nonatomic) LynxUIImageDrawParameter* param;

@end

@implementation LynxBorderRadiusImageProcessor

- (instancetype)initWithDrawParameter:(LynxUIImageDrawParameter*)param {
  if (self = [super init]) {
    self.param = param;
  }
  return self;
}

- (UIImage*)processImage:(UIImage*)image {
  // This modification is targeted at solving a specific type of problem:
  // When the client requests an animated image of the [.image] type through [BDWebImage] and pass
  // [LynxImageProcessor]s as a parameter, he will only receive a single frame of the image. Our way
  // of fixing it is to check if the image can be animated; if so, we will treat it as other
  // animated images who possess the [.gif] type.

  // "isAnimateImage" below is a member function inside the class BDImage which tells whether the
  // BDImage is animated or not.
  BOOL isAnimated = NO;
  SEL sel = NSSelectorFromString(@"isAnimateImage");
  if ([image respondsToSelector:sel]) {
    BOOL (*func)(id, SEL) = (BOOL(*)(id, SEL))[image methodForSelector:sel];
    isAnimated = (func)(image, sel);
  }

  // If the image is a gif, we don't use drawRect to process it, but simply return.
  if (isAnimated || image.images != nil) {
    return image;
  }
  CGSize size = self.param.frame.size;
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  UIGraphicsBeginImageContextWithOptions(size, NO, [LynxUIUnitUtils screenScale]);
  self.param.image = image;
  [LynxUIImage drawRect:rect withParameters:self.param];
  UIImage* output = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return output;
}

- (NSString*)cacheKey {
  return
      [NSString stringWithFormat:@"_LynxBorderRadiusImageProcessor_%@_%@_%ld_%@",
                                 NSStringFromUIEdgeInsets(self.param.borderWidth),
                                 NSStringFromUIEdgeInsets(self.param.padding),
                                 (long)self.param.resizeMode, NSStringFromCGRect(self.param.frame)];
}

@end

@implementation LynxImageShadowNode

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_SHADOW_NODE("image")
#else
LYNX_REGISTER_SHADOW_NODE("image")
#endif

@end

@interface LynxUIImage () <LynxMeasureDelegate>
@property(nonatomic, assign) UIViewContentMode resizeMode;
@property(nonatomic, assign) BOOL coverStart;
@property(nonatomic, assign) BOOL freed;
@property(nonatomic) LynxURL* src;
@property(nonatomic) LynxURL* placeholder;
@property(nonatomic) CGFloat blurRadius;
@property(nonatomic, assign) UIEdgeInsets capInsets;
@property(nonatomic, assign) CGFloat capInsetsScale;
@property(nonatomic) UIImage* image;
@property(nonatomic, strong) NSMutableDictionary<id, dispatch_block_t>* cancelBlocks;
@property(nonatomic, readwrite) NSInteger loopCount;
@property(nonatomic, readwrite) CGFloat preFetchWidth;
@property(nonatomic, readwrite) CGFloat preFetchHeight;
@property(nonatomic, assign) BOOL downsampling;
@property(nonatomic, assign) BOOL autoSize;
@property(nonatomic, assign) BOOL isOffScreen;
@property(nonatomic) BOOL deferSrcInvalidation;
@property(nonatomic, assign) NSInteger redBoxSizeWarningThreshold;
@property(nonatomic) NSDate* startRequestTime;
@property(nonatomic) BOOL useNewImage;
@property(nonatomic) NSDate* finishRequestTime;
@end

@implementation LynxUIImage {
  NSString* _preSrc;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("image")
#else
LYNX_REGISTER_UI("image")
#endif

- (instancetype)init {
  self = [super init];
  if (self) {
    _resizeMode = UIViewContentModeScaleToFill;
    _coverStart = false;
    _cancelBlocks = [NSMutableDictionary new];
    self.loopCount = 0;
    _preSrc = nil;
    _capInsetsScale = 1.0;
    _useNewImage = YES;
    _deferSrcInvalidation = false;
    _requestOptions = LynxImageDefaultOptions;
  }
  return self;
}

- (void)freeMemoryCache {
  if (self.isOffScreen && [LynxEnv getBoolExperimentSettings:LynxTrailFreeImageMemory]) {
    self.image = nil;
    [self freeImageCache];
  }
}

- (void)targetOnScreen {
  if (self.freed && self.view.image == nil &&
      [LynxEnv getBoolExperimentSettings:LynxTrailFreeImageMemory]) {
    self.isOffScreen = NO;
    self.freed = NO;
    [self requestImage];
  }
}

- (void)targetOffScreen {
  self.isOffScreen = YES;
  // release image memory caches when current lynxview entering into
  // background stack, trail for libra abtest, default close
  if ([LynxEnv getBoolExperimentSettings:LynxTrailFreeImageMemoryForce]) {
    [self freeMemoryCache];
  }
}

- (UIView*)createView {
  UIImageView* newImageView = [LynxService(LynxServiceImageProtocol) imageView];
  if (newImageView) {
    newImageView.clipsToBounds = YES;
    // Default contentMode UIViewContentModeScaleToFill
    newImageView.contentMode = UIViewContentModeScaleToFill;
    newImageView.userInteractionEnabled = YES;
    return newImageView;
  }
  UIImageView* image = [UIImageView new];
  image.clipsToBounds = YES;
  // Default contentMode UIViewContentModeScaleToFill
  image.contentMode = UIViewContentModeScaleToFill;
  image.userInteractionEnabled = YES;
  return image;
}

- (void)addExposure {
  BOOL enableExposure = [LynxEnv getBoolExperimentSettings:@"enable_image_exposure"];
  if (enableExposure) {
    self.internalSignature = [NSString stringWithFormat:@"lynx_image_%@", self];
  }
}

- (void)onImageReady:(UIImage*)image withRequest:(LynxURL*)requestURL {
  __weak typeof(self) weakSelf = self;
  __block void (^ready)(UIImage*, LynxURL*) = ^(UIImage* image, LynxURL* requestURL) {
    typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (image == nil) {
      strongSelf.view.image = image;
      strongSelf.view.animationImages = nil;
      return;
    }

    if (strongSelf.autoSize &&
        UIEdgeInsetsEqualToEdgeInsets(strongSelf.capInsets, UIEdgeInsetsZero)) {
      LynxShadowNodeOwner* owner = strongSelf.context.nodeOwner;
      if (!owner) {
        return;
      }
      LynxShadowNode* node = [owner nodeWithSign:strongSelf.sign];
      if (!node) {
        return;
      }
      [node setMeasureDelegate:strongSelf];
      [node setNeedsLayout];
    }

    if (strongSelf.loopCount <= 0) {
      strongSelf.view.image = image;
      strongSelf.view.animationImages = image.images;
      if (image.images != nil && [image.images count] > 1) {
        strongSelf.view.animationDuration = image.duration;
        [strongSelf.view startAnimating];
      }
      if (requestURL) {
        [requestURL updatePreviousUrl];
      }
    } else {
      if ([requestURL isPreviousUrl]) {
        return;
      }
      if (requestURL) {
        [requestURL updatePreviousUrl];
      }
      [LynxService(LynxServiceImageProtocol) handleAnimatedImage:image
                                                            view:strongSelf.view
                                                       loopCount:strongSelf.loopCount];
    }
  };
  if ([NSThread isMainThread]) {
    ready(image, requestURL);
  } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      ready(image, requestURL);
    });
  }
}

- (bool)updateLayerMaskOnFrameChangedInner:(BOOL)needAsyncDisplay URL:(LynxURL*)requestUrl {
  // we do not need to run super, as overflow is not used for image,
  // border-radius will be processed by myself
  if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
    return false;
  }
  if (needAsyncDisplay) {
    if (self.image != nil) {
      if ([self.image.images count] > 1 ||
          (UIEdgeInsetsEqualToEdgeInsets(self.backgroundManager.borderWidth, UIEdgeInsetsZero) &&
           UIEdgeInsetsEqualToEdgeInsets(self.padding, UIEdgeInsetsZero) &&
           ![self.backgroundManager hasDifferentBorderRadius])) {
        [self onImageReady:_image withRequest:requestUrl];
      } else {
        __weak typeof(self) weakSelf = self;
        [self displayAsyncWithCompletionBlock:^(UIImage* _Nonnull image) {
          [weakSelf onImageReady:image withRequest:requestUrl];
        }];
      }
    }
  } else {
    [self onImageReady:_image withRequest:requestUrl];
  }
  if (_resizeMode == UIViewContentModeScaleAspectFill && _coverStart) {
    CGFloat availableWidth = self.frame.size.width - self.padding.left - self.padding.right -
                             self.border.left - self.border.right;
    CGFloat availableHeight = self.frame.size.height - self.padding.top - self.padding.bottom -
                              self.border.top - self.border.bottom;
    CGFloat sourceWidth = _image.size.width;
    CGFloat sourceHeight = _image.size.height;
    float w_rate = sourceWidth / availableWidth;
    float h_rate = sourceHeight / availableHeight;
    if (h_rate > w_rate) {
      CGFloat h = w_rate * availableHeight;
      self.view.layer.contentsRect = CGRectMake(0, 0, 1, h / sourceHeight);
    } else {
      CGFloat w = h_rate * availableWidth;
      self.view.layer.contentsRect = CGRectMake(0, 0, w / sourceWidth, 1);
    }
  }
  return true;
}

- (bool)superUpdateLayerMaskOnFrameChanged {
  return [super updateLayerMaskOnFrameChanged];
}

- (bool)updateLayerMaskOnFrameChanged {
  self.view.clipsToBounds = YES;  // image'clipsToBounds should always be YES
  BOOL supportsProcessor = LynxImageFetchherSupportsProcessor(self.context.imageFetcher);
  return [self updateLayerMaskOnFrameChangedInner:!supportsProcessor URL:nil];
}

- (void)frameDidChange {
  [super frameDidChange];

  [self requestImage];
}

- (void)propsDidUpdate {
  [self addExposure];
  [super propsDidUpdate];
  [self requestImage];
}

UIEdgeInsets LynxRoundInsetsToPixel(UIEdgeInsets edgeInsets) {
  edgeInsets.top = round(edgeInsets.top);
  edgeInsets.bottom = round(edgeInsets.bottom);
  edgeInsets.left = round(edgeInsets.left);
  edgeInsets.right = round(edgeInsets.right);

  return edgeInsets;
}

- (BOOL)enableAsyncDisplay {
  // Images may or may not be displayed asynchronously; the default is AsyncDisplay.
  return _asyncDisplayFromTTML;
}

- (void)requestImage {
  self.image = nil;
  [self requestImage:_src];
  [self requestImage:_placeholder];
}

- (void)freeImageCache {
  self.freed = YES;
  [self resetImage];
}

- (bool)getEnableImageDownsampling {
  return ((LynxView*)self.context.rootView).templateRender.enableImageDownsampling;
}

- (BOOL)getTrailUseNewImage {
  return ((LynxView*)self.context.rootView).templateRender.trailNewImage;
}

- (bool)getPageConfigEnableNewImage {
  return ((LynxView*)self.context.rootView).templateRender.enableNewImage;
}

- (NSInteger)getRedBoxSizeWarningThreshold {
  return (int)((LynxView*)self.context.rootView).templateRender.redBoxImageSizeWarningThreshold;
}

- (BOOL)getSetUseNewImage {
  return [LynxEnv getBoolExperimentSettings:@"use_New_Image"];
}

- (BOOL)shouldUseNewImage {
  if ([self getTrailUseNewImage]) {
    return true;
  }
  if ([self getSetUseNewImage] && [self getPageConfigEnableNewImage] && _useNewImage) {
    return true;
  }
  return false;
}

- (void)redScreenReporter:(UIImage*)image {
  if (!image) {
    return;
  }
  self.redBoxSizeWarningThreshold = [self getRedBoxSizeWarningThreshold];
  bool overThresholdJudge = (self.updatedFrame.size.width * self.updatedFrame.size.height) > 0 &&
                            (image.size.width * image.size.height) /
                                    (self.updatedFrame.size.width * self.updatedFrame.size.height) >
                                self.redBoxSizeWarningThreshold;
  if (overThresholdJudge) {
    CGFloat memoryUse = image.size.width * image.size.height * 4;
    NSString* errorInfo = [NSString
        stringWithFormat:
            @"Image size is %d times bigger than your UI. Please consider downsampling it to "
            @"avoid protential OOM.\n"
            @"Red Box Warning Threshod: %d. Can be adjusted in pageConfig.\n"
            @"url:%@\n"
            @"image size: %f * %f\n"
            @"memory use: %f\n"
            @"component size: %f * %f\n",
            (int)self.redBoxSizeWarningThreshold, (int)self.redBoxSizeWarningThreshold,
            self.src.url.absoluteString, image.size.height, image.size.width, memoryUse,
            self.view.frame.size.height, self.view.frame.size.width];
    [self.context reportError:[LynxError lynxErrorWithCode:LynxErrorCodeBigImage
                                               description:errorInfo]];
  }
}

- (void)requestImage:(LynxURL*)requestUrl {
  if (_cancelBlocks[@(requestUrl.type)]) {
    _cancelBlocks[@(requestUrl.type)]();
    _cancelBlocks[@(requestUrl.type)] = nil;
  }
  NSURL* url = requestUrl.url;
  if (!url || [url.absoluteString isEqualToString:@""]) {
    return;
  }
  if (self.frame.size.width <= 0 && self.frame.size.height <= 0 && _preFetchWidth <= 0 &&
      _preFetchHeight <= 0) {
    return;
  }
  if (_autoSize && self.frame.size.width <= 0 && self.frame.size.height <= 0) {
    return;
  }
  NSMutableArray* processors = [NSMutableArray new];
  if (!UIEdgeInsetsEqualToEdgeInsets(_capInsets, UIEdgeInsetsZero)) {
    [processors addObject:[[LynxNinePatchImageProcessor alloc] initWithCapInsets:_capInsets
                                                                  capInsetsScale:_capInsetsScale]];
  }
  if (_blurRadius > 0) {
    [processors addObject:[[LynxBlurImageProcessor alloc] initWithBlurRadius:_blurRadius]];
  }
  BOOL supportsProcessor = LynxImageFetchherSupportsProcessor(self.context.imageFetcher);
  if (supportsProcessor) {
    BOOL hasNoBorderRadii =
        UIEdgeInsetsEqualToEdgeInsets(self.backgroundManager.borderWidth, UIEdgeInsetsZero) &&
        UIEdgeInsetsEqualToEdgeInsets(self.padding, UIEdgeInsetsZero) &&
        !LynxHasBorderRadii(self.backgroundManager.borderRadius);
    if (!hasNoBorderRadii) {
      [processors addObject:[[LynxBorderRadiusImageProcessor alloc]
                                initWithDrawParameter:self.drawParameter]];
    }
  }
  __weak typeof(self) weakSelf = self;
  static NSString* LynxImageEventLoad = @"load";
  CGSize size = CGSizeZero;
  if ((_preFetchWidth > 0 && _preFetchWidth > 0) &&
      (self.frame.size.width <= 0 || self.frame.size.height <= 0)) {
    size = CGSizeMake(_preFetchWidth, _preFetchHeight);
  } else {
    size = self.view.bounds.size;
  }

  LynxImageLoadCompletionBlock requestBlock = ^(UIImage* _Nullable image, NSError* _Nullable error,
                                                NSURL* _Nullable imageURL) {
    NSDate* getImageTime = [NSDate date];
    typeof(weakSelf) strongSelf = weakSelf;
    [strongSelf redScreenReporter:image];
    strongSelf.cancelBlocks[@(requestUrl.type)] = nil;
    // If enable NewImage, remember to free newImageRequest after cancel and complete
    if (strongSelf.useNewImage) {
      strongSelf.customImageRequest = nil;
    }
    NSString* errorDetail;
    BOOL isLatestImageURL = [requestUrl.url.absoluteString isEqualToString:imageURL.absoluteString];
    if (!isLatestImageURL) {
      return;
    }
    requestUrl.memoryCost = image.size.width * image.size.height * 4;
    if (error) {
      errorDetail = [NSString stringWithFormat:@"url:%@,%@", url, [error description]];
    }
    if (!errorDetail) {
      requestUrl.isSuccess = 1;
      if (requestUrl.type == LynxImageRequestPlaceholder && strongSelf.image) {
        return;
      }
      requestUrl.memoryCost = image.size.height * image.size.width * 4;
      strongSelf.image = image;
      // To enable gifs with corner-radius.
      // If the image is a gif, we call LynxUI::updateLayerMaskOnFrameChanged.
      // Using gifs with corner-radius in animation is highly unrecommended.
      if (strongSelf.image.images != nil) {
        [strongSelf onImageReady:image withRequest:requestUrl];
        if ([NSThread isMainThread]) {
          [strongSelf superUpdateLayerMaskOnFrameChanged];
        } else {
          dispatch_async(dispatch_get_main_queue(), ^{
            typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
              [strongSelf superUpdateLayerMaskOnFrameChanged];
            }
          });
        }
      }
      // If not a gif, we call LynxUIImage::updateLayerMaskOnFrameChanged.
      else {
        [strongSelf updateLayerMaskOnFrameChangedInner:!supportsProcessor URL:requestUrl];
      }
      if (requestUrl.type == LynxImageRequestSrc &&
          [strongSelf.eventSet valueForKey:LynxImageEventLoad]) {
        NSDictionary* detail = @{
          @"height" : [NSNumber numberWithFloat:roundf(image.size.height)],
          @"width" : [NSNumber numberWithFloat:roundf(image.size.width)]
        };
        [strongSelf.context.eventEmitter
            dispatchCustomEvent:[[LynxDetailEvent alloc] initWithName:LynxImageEventLoad
                                                           targetSign:strongSelf.sign
                                                               detail:detail]];
      }
    } else {
      [strongSelf reportURLSrcError:error type:requestUrl.type source:url];
    }
    NSDate* completeRequestTime = [NSDate date];
    requestUrl.fetchTime = [getImageTime timeIntervalSinceDate:strongSelf.startRequestTime];
    requestUrl.completeTime =
        [completeRequestTime timeIntervalSinceDate:strongSelf.startRequestTime];
    [strongSelf monitorReporter:requestUrl];
    [strongSelf reportImageInfo:requestUrl];
  };
  _startRequestTime = [NSDate date];
  BOOL downsampling = _downsampling || self.getEnableImageDownsampling;
  if (![self shouldUseNewImage]) {
    _cancelBlocks[@(requestUrl.type)] = [[LynxImageLoader sharedInstance]
        loadImageFromURL:url
                    size:size
             contextInfo:@{
               LynxImageFetcherContextKeyUI : self,
               LynxImageFetcherContextKeyDownsampling : @(downsampling)
             }
              processors:processors
            imageFetcher:self.context.imageFetcher
               completed:(LynxImageLoadCompletionBlock)requestBlock];
  } else {
    [self initResourceLoaderInformation];
    [requestUrl initResourceInformation];
    _cancelBlocks[@(requestUrl.type)] =
        [self loadNewImageFromURL:requestUrl
                             size:size
                      contextInfo:@{
                        LynxImageFetcherContextKeyUI : self,
                        LynxImageFetcherContextKeyDownsampling : @(downsampling),
                        LynxImageRequestOptions : [NSNumber numberWithLong:_requestOptions],

                      }
                       processors:processors
                        completed:(LynxImageLoadCompletionBlock)requestBlock];
  }
}

- (void)initResourceLoaderInformation {
  if (!self.resLoaderInfo) {
    self.resLoaderInfo = [NSMutableDictionary dictionary];
  }
  self.resLoaderInfo[@"res_loader_name"] = @"Lynx";
  self.resLoaderInfo[@"res_loader_version"] = [LynxVersion versionString] ?: @"";
}

- (dispatch_block_t)loadNewImageFromURL:(LynxURL*)url
                                   size:(CGSize)targetSize
                            contextInfo:(NSDictionary*)contextInfo
                             processors:(NSArray*)processors
                              completed:(LynxImageLoadCompletionBlock)completed {
  return [LynxService(LynxServiceImageProtocol) loadNewImageFromURL:url
                                                               size:targetSize
                                                        contextInfo:contextInfo
                                                         processors:processors
                                                          completed:completed
                                                        LynxUIImage:self];
}

- (void)reportImageInfo:(LynxURL*)currentUrl {
  if (![self shouldUseNewImage]) {
    return;
  }

  if (!currentUrl.resourceInfo) {
    return;
  }

  NSMutableDictionary* data = [NSMutableDictionary dictionary];
  if (currentUrl.isSuccess == 1) {
    currentUrl.resourceInfo[@"res_state"] = @"success";
    currentUrl.resourceInfo[@"res_size"] = [NSNumber numberWithFloat:currentUrl.memoryCost];

    NSMutableDictionary* resLoadPerf = [NSMutableDictionary dictionary];
    resLoadPerf[@"res_load_start"] =
        [NSNumber numberWithDouble:[_startRequestTime timeIntervalSince1970] * 1000];
    resLoadPerf[@"res_load_finish"] =
        [NSNumber numberWithDouble:[_finishRequestTime timeIntervalSince1970] * 1000];
    data[@"res_load_perf"] = resLoadPerf;
  } else {
    currentUrl.resourceInfo[@"res_state"] = @"failed";

    NSMutableDictionary* resLoadError = [NSMutableDictionary dictionary];
    resLoadError[@"res_error_msg"] =
        [NSString stringWithFormat:@"url:%@,%@", currentUrl.url, [currentUrl.error description]];
    NSNumber* originalErrorCode = [currentUrl.error.userInfo valueForKey:@"error_num"]
                                      ?: [NSNumber numberWithInteger:currentUrl.error.code];
    NSNumber* categorizedErrorCode =
        [LynxService(LynxServiceImageProtocol) getMappedCategorizedPicErrorCode:originalErrorCode];
    resLoadError[@"net_library_error_code"] = originalErrorCode ?: [NSNumber numberWithInt:-1];
    resLoadError[@"res_loader_error_code"] = categorizedErrorCode ?: [NSNumber numberWithInt:-1];
    data[@"res_load_error"] = resLoadError;
  }

  data[@"res_info"] = currentUrl.resourceInfo;
  data[@"res_loader_info"] = _resLoaderInfo;

  [LynxService(LynxServiceMonitorProtocol) reportResourceStatus:(LynxView*)self.context.rootView
                                                           data:data
                                                          extra:NULL];
}

- (void)reportURLSrcError:(NSError*)error
                     type:(LynxImageRequestType)requestType
                   source:(NSURL*)url {
  static NSString* LynxImageEventError = @"error";
  NSString* errorDetail = [NSString stringWithFormat:@"url:%@,%@", url, [error description]];
  NSNumber* errorCode =
      [error.userInfo valueForKey:@"error_num"] ?: [NSNumber numberWithInteger:error.code];
  NSNumber* categorizedErrorCode =
      [LynxService(LynxServiceImageProtocol) getMappedCategorizedPicErrorCode:errorCode];
  if (requestType == LynxImageRequestSrc && [self.eventSet valueForKey:LynxImageEventError]) {
    NSDictionary* detail = @{
      @"errMsg" : errorDetail ?: @"",
      @"error_code" : errorCode,
      @"lynx_categorized_code" : categorizedErrorCode ?: @(-1)
    };
    [self.context.eventEmitter
        dispatchCustomEvent:[[LynxDetailEvent alloc] initWithName:LynxImageEventError
                                                       targetSign:self.sign
                                                           detail:detail]];
  }
  NSDictionary* errorDic;
  if (url) {
    errorDic =
        @{@"src" : url.absoluteString ?: @"", @"type" : @"image", @"error_msg" : errorDetail};
  } else {
    errorDic = @{@"src" : @"", @"type" : @"image", @"error_msg" : errorDetail};
  }
  NSString* errorJSONString = [LynxConvertUtils convertToJsonData:errorDic];
  LynxError* err = [LynxError lynxErrorWithCode:LynxErrorCodeForResourceError
                                        message:errorJSONString];
  [self.context didReceiveResourceError:err];
}

- (void)monitorReporter:(LynxURL*)reportUrl {
  if (!reportUrl) {
    return;
  }
  NSDictionary* timeMetrics = @{
    @"fetchTime" : [NSNumber numberWithDouble:reportUrl.fetchTime],
    @"completeTime" : [NSNumber numberWithDouble:reportUrl.completeTime],
    @"fetchTimeStamp" : [NSString
        stringWithFormat:@"%lld", (uint64_t)(self.startRequestTime.timeIntervalSince1970 * 1000)],
    @"finishTimeStamp" :
        [NSString stringWithFormat:@"%lld", (uint64_t)((CFAbsoluteTimeGetCurrent() +
                                                        kCFAbsoluteTimeIntervalSince1970) *
                                                       1000)],
  };
  NSDictionary* templateMetric = @{
    @"url" : ((LynxView*)self.context.rootView).templateRender.url ?: @"",
    @"width" : @(self.image.size.width),
    @"height" : @(self.image.size.height),
    @"viewWidth" : @(self.view.frame.size.width),
    @"viewHeight" : @(self.view.frame.size.height),
  };
  NSDictionary* reportData = @{
    @"type" : @"image",
    @"image_url" : reportUrl.url.absoluteString ?: @"",
    @"timeMetrics" : timeMetrics,
    @"successRate" : [NSNumber numberWithInt:(int)reportUrl.isSuccess],
    @"metric" : templateMetric,
    @"memoryCost" : [NSNumber numberWithFloat:reportUrl.memoryCost],
  };
  // upload image memory info for devtool
  [[LynxMemoryListener shareInstance] uploadImageInfo:reportData];
  [LynxService(LynxServiceMonitorProtocol) reportImageStatus:@"lynx_image_status" data:reportData];
}

- (void)resetImage {
  if (self.view != nil) {
    self.view.image = nil;
    self.view.animationImages = nil;
  }
}

- (NSString*)illegalUrlHandler:(NSString*)value {
  // To handle some illegal symbols, such as chinese characters and [], etc
  // Query + Path characterset will cover all other urlcharacterset
  if (![[NSURL alloc] initWithString:value]) {
    NSMutableCharacterSet* characterSetForEncode = [[NSMutableCharacterSet alloc] init];
    [characterSetForEncode formUnionWithCharacterSet:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [characterSetForEncode formUnionWithCharacterSet:[NSCharacterSet URLPathAllowedCharacterSet]];
    value = [value stringByAddingPercentEncodingWithAllowedCharacters:characterSetForEncode];
  }
  return value;
}

LYNX_PROP_SETTER("src", setSrc, NSString*) {
  if (requestReset || value == nil) {
    self.image = nil;
    [self resetImage];
    _src = nil;
    return;
  }

  value = [self illegalUrlHandler:value];

  if (!_src) {
    _src = [[LynxURL alloc] init];
    _src.type = LynxImageRequestSrc;
  }
  if (![value isEqualToString:_src.url.absoluteString]) {
    self.image = nil;
    if (!_deferSrcInvalidation) {
      [self resetImage];
    }
    _src.url = [[NSURL alloc] initWithString:value];
  }
}

LYNX_PROP_SETTER("placeholder", setPlaceholder, NSString*) {
  if (requestReset || value == nil) {
    self.image = nil;
    [self resetImage];
    _placeholder = nil;
    return;
  }

  value = [self illegalUrlHandler:value];
  if (!_placeholder) {
    _placeholder = [[LynxURL alloc] init];
    _placeholder.type = LynxImageRequestPlaceholder;
  }
  if (![value isEqualToString:_placeholder.url.absoluteString]) {
    self.image = nil;
    if (!_deferSrcInvalidation) {
      [self resetImage];
    }
    _placeholder.url = [[NSURL alloc] initWithString:value];
  }
}

LYNX_PROP_SETTER("defer-src-invalidation", setDeferSrcInvalidation, BOOL) {
  if (requestReset) {
    value = false;
  }
  _deferSrcInvalidation = value;
}

LYNX_PROP_SETTER("mode", setMode, UIViewContentMode) {
  if (requestReset) {
    value = UIViewContentModeScaleToFill;
  }
  if (_resizeMode != value || self.view.contentMode != value) {
    _resizeMode = value;
    self.view.contentMode = _resizeMode;
  }
}

LYNX_PROP_SETTER("cover-start", setCoverStart, BOOL) {
  if (requestReset) {
    value = false;
  }
  if (_coverStart != value) {
    _coverStart = value;
  }
}

LYNX_PROP_SETTER("blur-radius", setBlurRadius, NSString*) {
  if (requestReset) {
    _blurRadius = 0;
  } else {
    LynxUI* rootUI = (LynxUI*)self.context.rootUI;
    UIView* rootView = self.context.rootView;
    LynxScreenMetrics* screenMetrics = self.context.screenMetrics;
    _blurRadius = [LynxUnitUtils toPtWithScreenMetrics:screenMetrics
                                             unitValue:value
                                          rootFontSize:rootUI.fontSize
                                           curFontSize:self.fontSize
                                             rootWidth:rootView.frame.size.width
                                            rootHeight:rootView.frame.size.height
                                         withDefaultPt:0];
  }
}

LYNX_PROP_SETTER("capInsets", setInnerCapInsets, NSString*) {
  if (requestReset) {
    _capInsets = UIEdgeInsetsZero;
  }
  UIEdgeInsets capInsets = _capInsets;
  NSArray* capInsetsProps = [value componentsSeparatedByString:@" "];
  const NSInteger count = [capInsetsProps count];

  capInsets.top = [self toCapInsetValue:count > 0 ? capInsetsProps[0] : nil];
  capInsets.right = count > 1 ? [self toCapInsetValue:capInsetsProps[1]] : capInsets.top;
  capInsets.bottom = count > 2 ? [self toCapInsetValue:capInsetsProps[2]] : capInsets.top;
  capInsets.left = count > 3 ? [self toCapInsetValue:capInsetsProps[3]] : capInsets.right;
  if (!UIEdgeInsetsEqualToEdgeInsets(_capInsets, capInsets)) {
    _capInsets = capInsets;
  }
}

LYNX_PROP_SETTER("cap-insets", setCapInsets, NSString*) {
  [self setInnerCapInsets:value requestReset:requestReset];
}

LYNX_PROP_SETTER("cap-insets-scale", setCapInsetsScale, NSString*) {
  if (requestReset) {
    _capInsetsScale = 1.0;
    return;
  }
  _capInsetsScale = [value floatValue];
}

LYNX_PROP_SETTER("loop-count", setLoopCount, NSInteger) {
  if (requestReset) {
    value = 0;
  }
  self.loopCount = value;
}

LYNX_PROP_SETTER("prefetch-width", setPreFetchWidth, NSString*) {
  if (requestReset) {
    value = @"-1px";
  }
  LynxScreenMetrics* screenMetrics = self.context.screenMetrics;

  _preFetchWidth = [LynxUnitUtils toPtWithScreenMetrics:screenMetrics
                                              unitValue:value
                                           rootFontSize:0
                                            curFontSize:0
                                              rootWidth:0
                                             rootHeight:0
                                          withDefaultPt:-1];
}

LYNX_PROP_SETTER("prefetch-height", setPreFetchHeight, NSString*) {
  if (requestReset) {
    value = @"-1px";
  }
  LynxScreenMetrics* screenMetrics = self.context.screenMetrics;
  _preFetchHeight = [LynxUnitUtils toPtWithScreenMetrics:screenMetrics
                                               unitValue:value
                                            rootFontSize:0
                                             curFontSize:0
                                               rootWidth:0
                                              rootHeight:0
                                           withDefaultPt:-1];
}

LYNX_PROP_SETTER("downsampling", setDownsampling, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _downsampling = value;
}

LYNX_PROP_SETTER("use-new-image", setUseNewImage, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _useNewImage = value;
}

LYNX_PROP_SETTER("auto-size", setAutoSize, BOOL) {
  if (requestReset) {
    value = NO;
  }
  _autoSize = value;
}

/**
 * @name: ignore-cdn-downgrade-cache-policy
 * @description:  If set, the downgraded CDN image will be store to disk cache.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
 **/
LYNX_PROP_SETTER("ignore-cdn-downgrade-cache-policy", setIgnoreCDNDowngradeCachePolicy, BOOL) {
  if (requestReset) {
    value = NO;
  }
  if (value) {
    _requestOptions = _requestOptions | LynxImageIgnoreCDNDowngradeCachePolicy;
  } else if (_requestOptions & LynxImageIgnoreCDNDowngradeCachePolicy) {
    _requestOptions ^= LynxImageIgnoreCDNDowngradeCachePolicy;
  }
}

/**
 * @name: ignore-memory-cache
 * @description:  If set, the request will not search memory cache.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
 **/
LYNX_PROP_SETTER("ignore-memory-cache", setIgnoreMemoryCache, BOOL) {
  if (requestReset) {
    value = NO;
  }
  if (value) {
    _requestOptions = _requestOptions | LynxImageIgnoreMemoryCache;
  } else if (_requestOptions & LynxImageIgnoreMemoryCache) {
    _requestOptions ^= LynxImageIgnoreMemoryCache;
  }
}

/**
 * @name: ignore-disk-cache
 * @description:  If set, the request will not search disk cache.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
 **/
LYNX_PROP_SETTER("ignore-disk-cache", setIgnoreDiskCache, BOOL) {
  if (requestReset) {
    value = NO;
  }
  if (value) {
    _requestOptions = _requestOptions | LynxImageIgnoreDiskCache;
  } else if (_requestOptions & LynxImageIgnoreDiskCache) {
    _requestOptions ^= LynxImageIgnoreDiskCache;
  }
}

/**
 * @name: not-cache-to-memory
 * @description:  If set, the requested image will not be stored to memory cache.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
 **/
LYNX_PROP_SETTER("not-cache-to-memory", setNotCacheToMemory, BOOL) {
  if (requestReset) {
    value = NO;
  }
  if (value) {
    _requestOptions = _requestOptions | LynxImageNotCacheToMemory;
  } else if (_requestOptions & LynxImageNotCacheToMemory) {
    _requestOptions ^= LynxImageNotCacheToMemory;
  }
}

/**
 * @name: not-cache-to-disk
 * @description:  If set, the requested image will not be stored to disk cache.
 * @category: different
 * @standardAction: keep
 * @supportVersion: 2.9
 **/
LYNX_PROP_SETTER("not-cache-to-disk", setNotCacheToDisk, BOOL) {
  if (requestReset) {
    value = NO;
  }
  if (value) {
    _requestOptions = _requestOptions | LynxImageNotCacheToDisk;
  } else if (_requestOptions & LynxImageNotCacheToDisk) {
    _requestOptions ^= LynxImageNotCacheToDisk;
  }
}

LYNX_UI_METHOD(startAnimate) {
  [self.view stopAnimating];
  [self restartAnimation];
}

- (CGFloat)toCapInsetValue:(NSString*)unitValue {
  const CGSize rootSize = self.context.rootView.frame.size;
  LynxScreenMetrics* screenMetrics = self.context.screenMetrics;
  return [LynxUnitUtils toPtWithScreenMetrics:screenMetrics
                                    unitValue:unitValue
                                 rootFontSize:((LynxUI*)self.context.rootUI).fontSize
                                  curFontSize:self.fontSize
                                    rootWidth:rootSize.width
                                   rootHeight:rootSize.height
                                withDefaultPt:0];
}

- (CGSize)frameSize {
  return CGRectIntegral(self.frame).size;
}

- (id)drawParameter {
  LynxUIImageDrawParameter* param = [[LynxUIImageDrawParameter alloc] init];
  param.image = self.image;
  param.borderWidth = self.backgroundManager.borderWidth;
  param.borderRadius = self.backgroundManager.borderRadius;
  param.padding = self.padding;
  param.frame = CGRectIntegral(self.frame);
  param.resizeMode = self.resizeMode;
  return param;
}

+ (void)drawRect:(CGRect)bounds withParameters:(id)drawParameters {
  LynxUIImageDrawParameter* param = drawParameters;

  UIEdgeInsets borderWidth = param.borderWidth;
  UIEdgeInsets padding = param.padding;
  LynxBorderRadii borderRadius = param.borderRadius;

  CGRect borderBounds;
  CGFloat initialBoundsWidth =
      param.frame.size.width - borderWidth.left - borderWidth.right - padding.left - padding.right;
  CGFloat initialBoundsHeight =
      param.frame.size.height - borderWidth.top - borderWidth.bottom - padding.top - padding.bottom;
  if (param.resizeMode == UIViewContentModeScaleAspectFit) {
    CGFloat min_scale = MIN(initialBoundsWidth / param.image.size.width,
                            initialBoundsHeight / param.image.size.height);
    CGFloat borderBoundsWidth = param.image.size.width * min_scale;
    CGFloat borderBoundsHeight = param.image.size.height * min_scale;
    borderBounds =
        CGRectMake(borderWidth.left + padding.left + initialBoundsWidth / 2 - borderBoundsWidth / 2,
                   borderWidth.top + padding.top + initialBoundsHeight / 2 - borderBoundsHeight / 2,
                   borderBoundsWidth, borderBoundsHeight);
  } else if (param.resizeMode == UIViewContentModeScaleAspectFill) {
    CGFloat max_scale = MAX(initialBoundsWidth / param.image.size.width,
                            initialBoundsHeight / param.image.size.height);
    CGFloat borderBoundsWidth = param.image.size.width * max_scale;
    CGFloat borderBoundsHeight = param.image.size.height * max_scale;
    borderBounds =
        CGRectMake(borderWidth.left + padding.left + initialBoundsWidth / 2 - borderBoundsWidth / 2,
                   borderWidth.top + padding.top + initialBoundsHeight / 2 - borderBoundsHeight / 2,
                   borderBoundsWidth, borderBoundsHeight);
  } else if (param.resizeMode == UIViewContentModeScaleToFill) {
    borderBounds = CGRectMake(borderWidth.left + padding.left, borderWidth.top + padding.top,
                              initialBoundsWidth, initialBoundsHeight);
  } else {  // "center"
    borderBounds = CGRectMake(
        borderWidth.left + padding.left + initialBoundsWidth / 2 - param.image.size.width / 2,
        borderWidth.top + padding.top + initialBoundsHeight / 2 - param.image.size.height / 2,
        param.image.size.width, param.image.size.height);
  }

  LynxBorderRadii radius = borderRadius;
  radius.topLeftX.val -= borderWidth.left + padding.left;
  radius.bottomLeftX.val -= borderWidth.left + padding.left;
  radius.topRightX.val -= borderWidth.right + padding.right;
  radius.bottomRightX.val -= borderWidth.right + padding.right;
  radius.topLeftY.val -= borderWidth.top + padding.top;
  radius.topRightY.val -= borderWidth.top + padding.top;
  radius.bottomLeftY.val -= borderWidth.bottom + padding.bottom;
  radius.bottomRightY.val -= borderWidth.bottom + padding.bottom;

  CGRect clipRaddiBounds =
      CGRectMake(borderWidth.left + padding.left, borderWidth.top + padding.top, initialBoundsWidth,
                 initialBoundsHeight);
  CGPathRef pathRef = [LynxBackgroundUtils createBezierPathWithRoundedRect:clipRaddiBounds
                                                               borderRadii:radius];

  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextAddPath(ctx, pathRef);
  CGContextClip(ctx);
  [param.image drawInRect:borderBounds];
  CGContextDrawPath(ctx, kCGPathFillStroke);
  CGPathRelease(pathRef);
}

- (void)restartAnimation {
  [super restartAnimation];
  if ([self isAnimated]) {
    [self startAnimating];
  }
}

- (BOOL)isAnimated {
  // use the image property of UIImageView to check whether this is an animated-image
  return self.image.images != nil;
}

- (BOOL)enableAccessibilityByDefault {
  return YES;
}

- (void)startAnimating {
  [self.view startAnimating];
}

- (CGSize)measureNode:(LynxLayoutNode*)node
            withWidth:(CGFloat)width
            widthMode:(LynxMeasureMode)widthMode
               height:(CGFloat)height
           heightMode:(LynxMeasureMode)heightMode {
  if (!_autoSize) {
    return CGSizeMake((widthMode == LynxMeasureModeDefinite) ? width : 0,
                      (heightMode == LynxMeasureModeDefinite) ? height : 0);
  }

  CGFloat tmpWidth = 0;
  CGFloat tmpHeight = 0;
  CGFloat imgWidth = self.image.size.width;
  CGFloat imgHeight = self.image.size.height;

  if (widthMode == LynxMeasureModeIndefinite || widthMode == LynxMeasureModeAtMost) {
    tmpWidth = INFINITY;
  } else if (widthMode == LynxMeasureModeDefinite) {
    tmpWidth = width;
  }

  if (heightMode == LynxMeasureModeIndefinite || heightMode == LynxMeasureModeAtMost) {
    tmpHeight = INFINITY;
  } else if (heightMode == LynxMeasureModeDefinite) {
    tmpHeight = height;
  }

  if (tmpWidth == INFINITY && tmpHeight == INFINITY) {
    tmpWidth = imgWidth;
    tmpHeight = imgHeight;
  } else if (tmpWidth == INFINITY && tmpHeight != INFINITY) {
    tmpWidth = imgWidth * (tmpHeight / imgHeight);
  } else if (tmpWidth != INFINITY && tmpHeight == INFINITY) {
    tmpHeight = imgHeight * (tmpWidth / imgWidth);
  }

  if (widthMode == LynxMeasureModeAtMost) {
    tmpWidth = MIN(tmpWidth, width);
  }
  if (heightMode == LynxMeasureModeAtMost) {
    tmpHeight = MIN(tmpHeight, height);
  }

  return CGSizeMake(tmpWidth, tmpHeight);
}

- (UIAccessibilityTraits)accessibilityTraitsByDefault {
  return UIAccessibilityTraitImage;
}

@end

@implementation LynxConverter (UIViewContentMode)

+ (UIViewContentMode)toUIViewContentMode:(id)value {
  if (!value || [value isEqual:[NSNull null]]) {
    return UIViewContentModeScaleAspectFill;
  }
  NSString* valueStr = [self toNSString:value];
  if ([valueStr isEqualToString:@"aspectFit"]) {
    return UIViewContentModeScaleAspectFit;
  } else if ([valueStr isEqualToString:@"aspectFill"]) {
    return UIViewContentModeScaleAspectFill;
  } else if ([valueStr isEqualToString:@"scaleToFill"]) {
    return UIViewContentModeScaleToFill;
  } else if ([valueStr isEqualToString:@"center"]) {
    return UIViewContentModeCenter;
  } else {
    return UIViewContentModeScaleAspectFill;
  }
}

@end
