//
//  ACCImageAlbumEditViewModel.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/11.
//

#import "ACCImageAlbumEditViewModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumEditImageInputInfo.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/RACSignal.h>
#import <ReactiveObjC/RACSubject.h>

NSString *const kACCImageAlbumEditDiaryGuideDisappearKey = @"kACCImageAlbumEditDiaryGuideDisappearKey";

@interface ACCImageAlbumEditViewModel ()

@property (nonatomic, assign) BOOL isImageScrollGuideAllowed;

@property (nonatomic, strong, readwrite) RACSignal *willSwitchImageAlbumEditModeSignal;
@property (nonatomic, strong, readwrite) RACSubject *willSwitchImageAlbumEditModeSubject;

@property (nonatomic, strong) RACSubject *scrollGuideDidDisappearSubject;

@end

@implementation ACCImageAlbumEditViewModel

- (void)dealloc
{
    [_willSwitchImageAlbumEditModeSubject sendCompleted];
    [_scrollGuideDidDisappearSubject sendCompleted];
}


- (RACSignal *)willSwitchImageAlbumEditModeSignal
{
    return self.willSwitchImageAlbumEditModeSubject;
}

- (RACSubject *)willSwitchImageAlbumEditModeSubject
{
    if (!_willSwitchImageAlbumEditModeSubject) {
        _willSwitchImageAlbumEditModeSubject = [RACSubject subject];
    }
    return _willSwitchImageAlbumEditModeSubject;
}

- (RACSignal *)scrollGuideDidDisappearSignal
{
    return self.scrollGuideDidDisappearSubject;
}

- (RACSubject *)scrollGuideDidDisappearSubject
{
    if (!_scrollGuideDidDisappearSubject) {
        _scrollGuideDidDisappearSubject = [RACSubject subject];
    }
    return _scrollGuideDidDisappearSubject;
}

- (CGSize)imageCoverSize
{
    CGSize imageSize = CGSizeMake(540, 960);
    
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    
    ACCImageAlbumEditImageInputInfo *imageInfo = [publishModel.repoImageAlbumInfo.imageEditOriginalImages acc_objectAtIndex:[self imageCoverIndex]];
    
    if (imageInfo && imageInfo.imageSize.width > 0 && imageInfo.imageSize.height > 0) {
        imageSize = imageInfo.imageSize;
        if (imageSize.width > 540.0) {
            CGFloat scale = imageSize.width / 540.0;
            imageSize = CGSizeMake(540.0, imageSize.height / scale);
        }
    }
    return imageSize;
}

- (NSInteger)imageCoverIndex
{
    AWEVideoPublishViewModel *publishModel = self.inputData.publishModel;
    
    return  publishModel.repoImageAlbumInfo.dynamicCoverIndex;
}

- (void)updateIsImageScrollGuideAllowed:(BOOL)allowed
{
    self.isImageScrollGuideAllowed = allowed;
}

- (void)sendScrollGuideDidDisappearSignal
{
    [self.scrollGuideDidDisappearSubject sendNext:nil];
}

@end
