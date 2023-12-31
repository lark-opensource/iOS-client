//
//  AWEModernStickerTitleCellViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/10/26.
//

#import "AWEModernStickerTitleCellViewModel.h"
#import <ReactiveObjC/RACSubject.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEModernStickerTitleCellViewModel ()

@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, assign) CGRect imageFrame;

@property (nonatomic, assign) CGRect titleFrame;

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) IESCategoryModel *category;

@end

@implementation AWEModernStickerTitleCellViewModel

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagNone, @"%s", __func__);
    [(RACSubject*)self.frameUpdateSignal sendCompleted];
}

- (instancetype)initWithCategory:(IESCategoryModel * _Nullable)category
               calculateDelegate:(id<AWEModernStickerTitleCellViewModelCalculateDelegate>)calculateDelegate {
    if (self = [super init]) {
        _frameUpdateSignal = [RACSubject subject];
        _calculateDelegate = calculateDelegate;
        _category = category;
        _title = [category.categoryName copy];

        [self parseExtra];

        [self update];
    }
    return self;
}

- (BOOL)isFavorite {
    return self.category == nil;
}

- (BOOL)shouldUseIconDisplay {
    return [self.category shouldUseIconDisplay];
}

- (BOOL)shouldShowYellowDot {
    return [self.category showRedDotWithTag:@"new"];
}

- (void)markAsReaded {
    [self.category markAsReaded];
}

#pragma mark - Private

- (void)parseExtra {
    NSError *error = nil;
    if (self.category.extra.length == 0) {
        return;
    }
    NSData *data = [self.category.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        NSAssert(!error, @"json serialization failed!!! error=%@", error);
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"json serialization failed!!! error=%@", error);
            // 兜底，json解析失败也显示title
            _title = [self.category.categoryName copy];
        } else {
            BOOL showIconOnly = NO;
            if (json[@"is_show_icon_only"]) {
                showIconOnly = [json[@"is_show_icon_only"] boolValue];
            }
            _title = showIconOnly ? nil : [self.category.categoryName copy];
        }
    }
}

- (void)update {
    @weakify(self);
    [self calculateCategoryFrame];
    // recalculate after dowload image
    if (self.category.selectedIconUrls.count > 0) {
        [ACCWebImage() requestImageWithURLArray:[self.category.selectedIconUrls copy] completion:^(UIImage *image, NSURL *url, NSError *error) {
            @strongify(self);
            if (!image || error || !url) {
                AWELogToolError(AWELogToolTagNone, @"sticker title cell vm download image failed, url=%@|selectedIconUrls=%@|error=%@", url, url, error);
            }

            self.image = image;
            [self calculateCategoryFrame];
        }];
    }
}

- (void)calculateCategoryFrame {
    if ([self.calculateDelegate respondsToSelector:@selector(modernStickerTitleCellViewModel:frameWithTitle:image:completion:)]) {
        [self.calculateDelegate modernStickerTitleCellViewModel:self
                                                 frameWithTitle:self.title
                                                          image:self.image
                                                     completion:^(CGFloat cellWidth, CGRect titleFrame, CGRect imageFrame) {
            self.cellWidth = cellWidth;
            self.imageFrame = imageFrame;
            self.titleFrame = titleFrame;

            acc_dispatch_main_async_safe(^{
                [(RACSubject*)self.frameUpdateSignal sendNext:nil];
            });
        }];
    }
}

@end
