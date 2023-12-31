//
//  BDUGSystemShare.m
//  BDUGShare
//
//  Created by zhxsheng on 2018/7/20.
//
//

#import "BDUGSystemShare.h"
#import "BDUGShareAdapterSetting.h"

#if __has_include(<LinkPresentation\\/LinkPresentation.h>)
#import <LinkPresentation/LinkPresentation.h>
#endif

NSString * const BDUGSystemShareErrorDomain = @"BDUGSystemShareErrorDomain";

@interface BDUGSystemShare () <UIActivityItemSource>

@property (nonatomic, copy) UIActivityViewControllerCompletionWithItemsHandler handler;

@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, strong) UIImage *currentImage;

@property (nonatomic, assign) CGRect popoverRect;
@property (nonatomic, strong) NSArray<__kindof UIActivity *> *applicationActivities;
@property (nonatomic, strong) NSArray<UIActivityType> *excludedActivityTypes; // default is nil. activity types listed will not be displayed

@end

@implementation BDUGSystemShare

static BDUGSystemShare *shareInstance;
+ (instancetype)sharedSystemShare {
    static dispatch_once_t onceToken;
    static BDUGSystemShare *shareInstance;
    dispatch_once(&onceToken, ^{
        shareInstance = [[BDUGSystemShare alloc] init];
    });
    return shareInstance;
}

+ (void)setPopoverRect:(CGRect)popoverRect {
    [BDUGSystemShare sharedSystemShare].popoverRect = popoverRect;
}

+ (void)setApplicationActivities:(NSArray <__kindof UIActivity *> *)applicationActivities {
    [BDUGSystemShare sharedSystemShare].applicationActivities = applicationActivities;
}

+ (void)setExcludedActivityTypes:(NSArray <UIActivityType> *)excludedActivityTypes {
    [BDUGSystemShare sharedSystemShare].excludedActivityTypes = excludedActivityTypes;
}

+ (void)shareImage:(UIImage *)image completion:(UIActivityViewControllerCompletionWithItemsHandler)completion
{
    [self shareWithTitle:nil image:image url:nil completion:completion];
}

+ (void)shareFileWithSandboxPath:(NSString *)sandboxPath completion:(UIActivityViewControllerCompletionWithItemsHandler)completion
{
    NSString *videoPath = sandboxPath;
    NSURL *shareURL = [NSURL fileURLWithPath:videoPath];
    [self shareWithTitle:nil image:nil url:shareURL completion:completion];
}

+ (void)shareWithTitle:(NSString *)title image:(UIImage *)image url:(NSURL *)url completion:(UIActivityViewControllerCompletionWithItemsHandler)completion {
    [BDUGSystemShare sharedSystemShare].currentTitle = title;
    [BDUGSystemShare sharedSystemShare].currentURL = url;
    [BDUGSystemShare sharedSystemShare].currentImage = image;
    
    NSMutableArray * ary = [NSMutableArray array];
    [ary addObject:[BDUGSystemShare sharedSystemShare]];
    if (image) {
        if (![image isMemberOfClass:[UIImage class]]) {
            UIImage *newImage = [[UIImage alloc] initWithCGImage:image.CGImage];
            [ary addObject:newImage];
        } else {
            [ary addObject:image];
        }
    }
    [self shareWithActivityItems:ary completion:completion];
}

+ (void)shareWithActivityItems:(NSArray *)activityItems completion:(UIActivityViewControllerCompletionWithItemsHandler)completion {
    UIViewController *topVC = [[BDUGShareAdapterSetting sharedService] topmostViewController];
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    UIActivityViewController * aController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:[BDUGSystemShare sharedSystemShare].applicationActivities];
    aController.excludedActivityTypes = [BDUGSystemShare sharedSystemShare].excludedActivityTypes;
    if (completion) {
        aController.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
            !completion ?: completion(activityType, completed, returnedItems, activityError);
        };
    }
    CGRect popoverRect = [BDUGSystemShare sharedSystemShare].popoverRect;
    if (CGRectEqualToRect(popoverRect, CGRectZero)) {
        popoverRect = CGRectMake(topVC.view.frame.size.width/2, topVC.view.frame.size.height * 3.f/4.f, 0, 0);
    }
    if ([[BDUGShareAdapterSetting sharedService] isPadDevice]) {
        UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:aController];
        [popup presentPopoverFromRect:popoverRect inView:topVC.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }
    else {
        [topVC presentViewController:aController animated:YES completion:nil];
    }
}

#pragma mark - UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    if (self.currentURL) {
        return self.currentURL;
    }
    if (self.currentImage) {
        return self.currentImage;
    }
    if (self.currentTitle) {
        return self.currentTitle;
    }
    return @"";
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(UIActivityType)activityType {
    if ([activityType isEqualToString:@"com.tencent.xin.sharetimeline"]) {
        if (self.currentTitle && self.currentURL) {
            return [NSString stringWithFormat:@"%@ %@", self.currentTitle, self.currentURL];
        }
    }
    if (self.currentURL) {
        return self.currentURL;
    }
    return self.currentTitle;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(UIActivityType)activityType {
    return self.currentTitle;
}

- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController thumbnailImageForActivityType:(UIActivityType)activityType suggestedSize:(CGSize)size {
    return self.currentImage;
}

#if __has_include(<LinkPresentation\\/LinkPresentation.h>)
- (LPLinkMetadata *)activityViewControllerLinkMetadata:(UIActivityViewController *)activityViewController  API_AVAILABLE(ios(13.0)) {
    LPLinkMetadata *metaData = [[LPLinkMetadata alloc] init];
    metaData.originalURL = self.currentURL;
    metaData.URL = self.currentURL;
    metaData.title = self.currentTitle;
    metaData.imageProvider = [[NSItemProvider alloc] initWithObject:self.currentImage];
    return metaData;
}
#endif
@end

