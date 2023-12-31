//
//  ACCImageAlbumSessionPlayerViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/17.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumData.h"
#import "ACCImageAlbumEditorSessionProtocol.h"


@interface ACCImageAlbumSessionPlayerViewModel : NSObject <ACCImageAlbumEditorSessionProtocolSubPlayer>

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithImageAlbumData:(ACCImageAlbumData *_Nonnull)albumData
                         containerSize:(CGSize)containerSize;

@property (nonatomic, copy) void(^onAllRenderOperationsCompleteHandler)(void);
@property (nonatomic, copy) void(^onStickerRecovered)(NSInteger uniqueId, NSInteger stickerId);

/// 标记当前的图片已经有做过修改，下次导出任务开始之前会重新渲染当前的图片
/// 适用于类似贴纸增删改，加滤镜等只应用当前的图片的操作，不会立即导出不影响性能
- (void)markCurrentImageHasBeenModify;

/// 重新导出所有图片，会立即开始导出，适用于类似HDR这种应用图片的操作
- (void)reloadAllPlayerItems;

/// return nil  if not rendered
- (UIImage *_Nullable)renderedImageAtIndex:(NSInteger)index;

/// 获取空闲的editor，如果正在渲染其他的item则返回nil
/// 适用于更新对应index对应数据，如果非空闲则无需刷新，在处理完任务之后会自动更新数据
- (ACCImageAlbumEditor *_Nullable)idleImageEditorIfExistAtIndex:(NSInteger)index;
- (ACCImageAlbumEditor *_Nullable)currentIdleImageEditorIfExist;

/// 如果加载过图片则返回
- (ACCImageAlbumEditor *_Nullable)anyReloadedImageEditorIfExist;

// 对低端机会有一些加载上的一些优化，目前仅iPhone6S及其以下会开启，高端机不需要，开启反而会浪费性能
@property (nonatomic, assign, readonly) BOOL isLowLevelDeviceOpt;

/// for debug hook
- (void)onDebugInfoLogChanged:(NSString *_Nullable)debugLogString;
- (void)debugCheckPreloadIndex:(NSArray <NSNumber *> *_Nullable)indexs
                  currentIndex:(NSInteger)currentIndex
                     itemCount:(NSInteger)itemCount;

@end

