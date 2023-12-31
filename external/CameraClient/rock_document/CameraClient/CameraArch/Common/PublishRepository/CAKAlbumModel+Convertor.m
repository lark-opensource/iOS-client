//
//  CAKAlbumModel+Convertor.m
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/12/31.
//

#import <CreativeKit/NSArray+ACCAdditions.h>
#import "CAKAlbumModel+Convertor.h"
#import <objc/runtime.h>
#import "CAKAlbumAssetModel+Convertor.h"

@interface CAKAlbumModel (Convertor)

@property (nonatomic, strong) AWEAlbumModel *originalStudioAlbumModel;

@end

@implementation CAKAlbumModel (Convertor)

+ (instancetype)createWithStudioAlbum:(AWEAlbumModel *)albumModel
{
    if (!albumModel) {
        return nil;
    }
    NSAssert([albumModel isKindOfClass:[AWEAlbumModel class]], @"model class type wrong");
    
    CAKAlbumModel *result = [[CAKAlbumModel alloc] init];
    result.localIdentifier = albumModel.localIdentifier;
    result.result = albumModel.result;
    result.name = albumModel.name;
    result.count = albumModel.count;
    result.isCameraRoll = albumModel.isCameraRoll;
    result.lastUpdateDate = albumModel.lastUpdateDate;
    result.models = [CAKAlbumAssetModel createWithStudioArray:albumModel.models];
    
    result.originalStudioAlbumModel = albumModel;
    return result;
}

- (AWEAlbumModel *)convertToStudioAlbum
{
    AWEAlbumModel *studioAlbum = self.originalStudioAlbumModel ?: [[AWEAlbumModel alloc] init];
    studioAlbum.localIdentifier = self.localIdentifier;
    studioAlbum.result = self.result;
    studioAlbum.name = self.name;
    studioAlbum.count = self.count;
    studioAlbum.isCameraRoll = self.isCameraRoll;
    studioAlbum.lastUpdateDate = self.lastUpdateDate;
    studioAlbum.models = [CAKAlbumAssetModel convertToStudioArray:self.models];
    return studioAlbum;
}

+ (NSArray<CAKAlbumModel *> *)createWithStudioArray:(NSArray<AWEAlbumModel *> *)studioAlbumsArray
{
    NSMutableArray<CAKAlbumModel *> *result = [NSMutableArray array];
    [studioAlbumsArray enumerateObjectsUsingBlock:^(AWEAlbumModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:[AWEAlbumModel class]], @"model type wrong");
        [result acc_addObject:[CAKAlbumModel createWithStudioAlbum:obj]];
    }];
    return [NSArray arrayWithArray:result];
}

+ (NSArray<AWEAlbumModel *> *)convertToStudioArray:(NSArray<CAKAlbumModel *> *)cakAlbumsArray
{
    NSMutableArray<AWEAlbumModel *> *result = [NSMutableArray array];
    [cakAlbumsArray enumerateObjectsUsingBlock:^(CAKAlbumModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:[CAKAlbumModel class]], @"model type wrong");
        [result acc_addObject:[obj convertToStudioAlbum]];
    }];
    return [NSArray arrayWithArray:result];
}

- (AWEAlbumModel *)originalStudioAlbumModel
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalStudioAlbumModel:(AWEAlbumModel *)originalStudioAlbumModel
{
    objc_setAssociatedObject(self, @selector(originalStudioAlbumModel), originalStudioAlbumModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
