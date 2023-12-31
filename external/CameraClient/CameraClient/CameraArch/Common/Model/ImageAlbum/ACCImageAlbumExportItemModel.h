//
//  ACCImageAlbumExportItemModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/18.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface ACCImageAlbumExportItemModel : NSObject

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) CGSize imageSize;

@property (nonatomic, assign) CGFloat imageScale;

- (BOOL)fileExists;

+ (NSArray <NSURL *> *)filePathURLsWithItemModels:(NSArray <ACCImageAlbumExportItemModel *> *)itemModels;

@end

NS_ASSUME_NONNULL_END
