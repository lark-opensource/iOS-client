//
//  ACCImageAlbumEditorExportData.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/2/18.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"


@class ACCImageAlbumItemModel;

@interface ACCImageAlbumEditorExportInputData: NSObject

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithImageItem:(ACCImageAlbumItemModel *_Nonnull)imageItem
                            index:(NSInteger)index
                      exportTypes:(ACCImageAlbumEditorExportTypes)exportTypes;

@property (nonatomic, assign, readonly) ACCImageAlbumEditorExportTypes exportTypes;

@property (nonatomic, assign, readonly) NSInteger index;

@property (nonatomic, strong, readonly) ACCImageAlbumItemModel *_Nullable imageItem;

/// if 'resultTypes' contain 'filePath' mode, 'savePath' must not be empty
@property (nonatomic, copy) NSString *_Nullable savePath;

/// default is CGSizeZero，export original size if 'targetSize' is  invaild
@property (nonatomic, assign) CGSize targetSize;

/// export original image or edit image
@property (nonatomic, assign) BOOL usingOriginalImage;

@end

@interface ACCImageAlbumEditorExportOutputData: NSObject

@property (nonatomic, copy) NSString *_Nullable filePath;

@property (nonatomic, strong) UIImage *_Nullable image;

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, assign) CGFloat imageScale;

@end

