//
//  ACCRecordSelectPropViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/9.
//

#import "ACCRecordSelectPropViewModel.h"
#import <CreativeKit/ACCMacros.h>
#import <BDWebImage/BDWebImageManager.h>

@interface ACCRecordSelectPropViewModel()
@property (nonatomic, strong, readwrite) RACSignal *clickSelectPropBtnSignal;
@property (nonatomic, strong, readwrite) RACSubject *clickSelectPropBtnSubject;
@end


@implementation ACCRecordSelectPropViewModel
@synthesize selectPropDisplayType = _selectPropDisplayType;
@synthesize canShowUploadVideoLabel = _canShowUploadVideoLabel;
@synthesize canShowStickerPanelAtLaunch = _canShowStickerPanelAtLaunch;

#pragma mark - Life Cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [_clickSelectPropBtnSubject sendCompleted];
}

#pragma mark - getter

- (RACSignal *)clickSelectPropBtnSignal
{
    return self.clickSelectPropBtnSubject;
}

- (RACSubject *)clickSelectPropBtnSubject
{
    if (!_clickSelectPropBtnSubject) {
        _clickSelectPropBtnSubject = [RACSubject subject];
    }
    return _clickSelectPropBtnSubject;
}

#pragma mark - setter

- (void)setSelectPropDisplayType:(ACCRecordSelectPropDisplayType)selectPropDisplayType
{
    _selectPropDisplayType = selectPropDisplayType;
}

#pragma mark - public methods

- (void)sendSignalAfterClickSelectPropBtn
{
    [self.clickSelectPropBtnSubject sendNext:nil];
}

- (void)configStickerBtnWithURLArray:(NSArray <NSString *> *)urlArray
                               index:(NSInteger)index
                          completion:(void(^)(UIImage *image))completion
{
    if (urlArray.count == 0 || index > urlArray.count - 1) {
        return;
    }
    id url = urlArray[index];
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:url];
    }
    if (![url isKindOfClass:[NSURL class]]) {
        return;
    }

    @weakify(self);
    [self p_configStickerBtnWithURL:(NSURL *)url completion:^(UIImage *image) {
        @strongify(self);
        if (!image) {
            if (index == urlArray.count - 1) {
                return;
            } else {
                [self configStickerBtnWithURLArray:urlArray index:(index + 1) completion:completion];
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completion, image);
            });
        }
    }];
}

#pragma mark - private methods

- (void)p_configStickerBtnWithURL:(NSURL *)url completion:(void(^)(UIImage *image))completion __attribute__((annotate("csa_ignore_block_use_check")))
{
    if (!url) {
        return;
    }
    BDWebImageManager *imageManager = [BDWebImageManager sharedManager];
    BDImageCacheType type = BDImageCacheTypeDisk;
    UIImage *cacheImage = [[BDImageCache sharedImageCache] imageForKey:[imageManager requestKeyWithURL:url] withType:&type];
    if (cacheImage) {
        ACCBLOCK_INVOKE(completion, cacheImage);
    } else {
        [imageManager requestImage:url alternativeURLs:nil options:0 cacheName:nil transformer:nil progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
        } complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if (!request.currentRequestURL || error || !image) {
                ACCBLOCK_INVOKE(completion, nil);
                return ;
            }
            ACCBLOCK_INVOKE(completion, image);
        }];
    }
}

- (ACCGroupedPredicate *)canShowUploadVideoLabel
{
    if (_canShowUploadVideoLabel == nil) {
        _canShowUploadVideoLabel = [[ACCGroupedPredicate alloc] init];
    }
    return _canShowUploadVideoLabel;
}

- (ACCGroupedPredicate *)canShowStickerPanelAtLaunch
{
    if (_canShowStickerPanelAtLaunch == nil) {
        _canShowStickerPanelAtLaunch = [[ACCGroupedPredicate alloc] init];
    }
    return _canShowStickerPanelAtLaunch;
}

@end
