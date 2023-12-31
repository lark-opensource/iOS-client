//
//  ACCStickerHierarchyManager.h
//  CameraClient
//
//  Created by liuqing on 2020/6/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCStickerContainerView;
@class ACCBaseStickerView;

@interface ACCStickerHierarchyManager : NSObject

- (instancetype)initWithContainer:(ACCStickerContainerView *)container
              hierarchyComparator:(NSComparator)cmptr;

- (void)addStickerView:(__kindof ACCBaseStickerView *)stickerView;
- (void)removeStickerView:(UIView *)stickerView;
- (void)activeStickerView:(__kindof ACCBaseStickerView *)stickerView;
- (void)removeAllStickerViews;

// lower fisrt with same hierarchy id, group higher with higher hierarchy id
- (NSArray<__kindof ACCBaseStickerView *> *)allStickerViews;
// the same with UI display, the higher the display, the more forward the position in array
- (NSArray<__kindof ACCBaseStickerView *> *)touchStickerViews;
- (NSArray<__kindof ACCBaseStickerView *> *)stickerViewsWithTypeId:(id)typeId;
- (NSArray<__kindof ACCBaseStickerView *> *)stickerViewsWithHierarchyId:(id)hierarchyId;

- (nullable __kindof ACCBaseStickerView *)stickerViewWithContentView:(UIView *)contentView;

- (BOOL)hierarchyInStickerView:(__kindof ACCBaseStickerView *)stickerViewA higherThanStickerView:(__kindof ACCBaseStickerView *)stickerViewB;

@end

NS_ASSUME_NONNULL_END
