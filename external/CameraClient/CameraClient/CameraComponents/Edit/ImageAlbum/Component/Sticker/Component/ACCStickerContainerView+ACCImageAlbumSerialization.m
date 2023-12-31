//
//  ACCStickerContainerView+ACCImageAlbumSerialization.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/30.
//

#import "ACCStickerContainerView+ACCImageAlbumSerialization.h"
#import "ACCSerialization.h"

@implementation ACCStickerContainerView (ACCImageAlbumSerialization)

- (NSArray<NSObject<ACCSerializationProtocol> *> *)allStickerStorageModels
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [[self allStickerViews] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class viewClass = obj.contentView.class;
        Class storageClass = NSClassFromString([NSStringFromClass(viewClass) stringByAppendingString:@"StorageModel"]);
        
        id storageModel = [ACCSerialization transformOriginalObj:obj to:storageClass];
        if (storageModel) {
            [result addObject:storageModel];
        }
    }];
    
    return result;
}

- (NSArray<NSObject<ACCSerializationProtocol> *> *)stickerStorageModelsWithTypeId:(id)typeId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [[self stickerViewsWithTypeId:typeId] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class viewClass = obj.contentView.class;
        Class storageClass = NSClassFromString([NSStringFromClass(viewClass) stringByAppendingString:@"StorageModel"]);
        
        id storageModel = [ACCSerialization transformOriginalObj:obj to:storageClass];
        if (storageModel) {
            [result addObject:storageModel];
        }
    }];
    
    return result;
}

@end
