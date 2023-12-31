//
//  ACCImageAlbumStickerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/31.
//

#import "ACCImageAlbumStickerModel.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMacros.h>
@interface ACCImageAlbumStickerModel ()

@end

@implementation ACCImageAlbumStickerModel
@synthesize param = _param;

- (ACCImageAlbumStickerProps *)param
{
    if (!_param) {
        _param = [ACCImageAlbumStickerProps defaultProps];
    }
    return _param;
}

- (void)deepCopyValuesIfNeedFromTarget:(ACCImageAlbumStickerModel *)target
{
    [super deepCopyValuesIfNeedFromTarget:target];
    
    if (![target isKindOfClass:[ACCImageAlbumStickerModel class]]) {
        NSAssert(NO, @"check");
        return;
    }
    _param = [target.param copy];
}

- (BOOL)isCustomerSticker
{
    return [self.userInfo acc_boolValueForKey:@"isCustomSticker" defaultValue:NO];
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    [super amazingMigrateResourceToNewDraftWithTaskId:taskId];
    
    // 理论上不会用到这个值，防止后续留坑还是顺便在迁移的时候重新赋值了
    if ([self isCustomerSticker] && !ACC_isEmptyString([self.userInfo acc_stringValueForKey:@"customStickerFilePath"])) {
        
        NSMutableDictionary *temp = [self.userInfo mutableCopy];
        temp[@"customStickerFilePath"] = [self getAbsoluteFilePath];
        self.userInfo = [temp copy];
    }
}

@end

@implementation ACCImageAlbumStickerRecoverModel

@end

@interface  ACCImageAlbumStickerProps ()

@property (nonatomic, copy) NSString *boundingBoxString;

@end

@implementation ACCImageAlbumStickerProps

+ (instancetype)defaultProps
{
    ACCImageAlbumStickerProps *props = [[ACCImageAlbumStickerProps alloc] init];
    props.alpha = 1.f;
    props.scale = 1.f;
    props.absoluteScale = 1.f;
    props.offsetX = [self centerOffset].x;
    props.offsetY = [self centerOffset].y;
    return props;
}

+ (CGPoint)centerOffset
{
    return CGPointMake(0.5f, 0.5f);
}

- (CGPoint)offset
{
    return CGPointMake(self.offsetX, self.offsetY);
}

- (void)updateOffset:(CGPoint)offset
{
    self.offsetX = offset.x;
    self.offsetY = offset.y;
}

- (void)updateBoundingBox:(UIEdgeInsets)boundingBox
{
    self.boundingBoxString = NSStringFromUIEdgeInsets(boundingBox);
}

- (UIEdgeInsets)boundingBox
{
    if (ACC_isEmptyString(self.boundingBoxString)) {
        return UIEdgeInsetsZero;
    }
    
    return UIEdgeInsetsFromString(self.boundingBoxString);
}

@end
