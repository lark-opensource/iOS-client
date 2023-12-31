//
//  ACCImageAlbumEditorExportData.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/2/18.
//

#import "ACCImageAlbumEditorExportData.h"


@implementation ACCImageAlbumEditorExportInputData

- (instancetype)initWithImageItem:(ACCImageAlbumItemModel *)imageItem
                            index:(NSInteger)index
                      exportTypes:(ACCImageAlbumEditorExportTypes)exportTypes
{
    if (self = [super init]) {
        _imageItem = imageItem;
        _index = index;
        _exportTypes = exportTypes;
    }
    return self;
}

@end

@implementation ACCImageAlbumEditorExportOutputData


@end

