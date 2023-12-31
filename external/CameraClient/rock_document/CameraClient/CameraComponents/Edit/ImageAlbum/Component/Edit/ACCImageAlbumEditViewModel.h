//
//  ACCImageAlbumEditViewModel.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/11.
//

#import "ACCImageAlbumEditServiceProtocol.h"
#import "ACCEditViewModel.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString *const kACCImageAlbumEditDiaryGuideDisappearKey;

@class RACSignal<__covariant ValueType>;

@interface ACCImageAlbumEditViewModel : ACCEditViewModel <ACCImageAlbumEditServiceProtocol>

- (CGSize)imageCoverSize;
- (NSInteger)imageCoverIndex;

- (void)updateIsImageScrollGuideAllowed:(BOOL)allowed;

- (void)sendScrollGuideDidDisappearSignal;

@end

NS_ASSUME_NONNULL_END
