//
//  ACCImageAlbumCropViewModel.h
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import "ACCEditViewModel.h"
#import "ACCImageAlbumCropServiceProtocol.h"
#import "ACCImageAlbumEditorDefine.h"

extern const CGFloat ACCImageAlbumCropControlViewHeight;
extern const CGFloat ACCImageAlbumCropControlViewCornerRadius;

@interface ACCImageAlbumCropViewModel : ACCEditViewModel <ACCImageAlbumCropServiceProtocol>

+ (NSString *)cropTitle;

@end
