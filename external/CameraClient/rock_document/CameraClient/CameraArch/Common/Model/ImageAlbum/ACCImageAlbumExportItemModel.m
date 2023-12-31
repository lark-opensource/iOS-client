//
//  ACCImageAlbumExportItemModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/18.
//

#import "ACCImageAlbumExportItemModel.h"

@implementation ACCImageAlbumExportItemModel

- (BOOL)fileExists
{
    return self.filePath && [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
}

+ (NSArray<NSURL *> *)filePathURLsWithItemModels:(NSArray<ACCImageAlbumExportItemModel *> *)itemModels
{
    NSMutableArray *fileURLs = [NSMutableArray array];
    
    [itemModels.copy enumerateObjectsUsingBlock:^(ACCImageAlbumExportItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCImageAlbumExportItemModel.class] && obj.filePath) {
            [fileURLs addObject:[NSURL fileURLWithPath:obj.filePath]];
        }
    }];
    return fileURLs;
}

@end
