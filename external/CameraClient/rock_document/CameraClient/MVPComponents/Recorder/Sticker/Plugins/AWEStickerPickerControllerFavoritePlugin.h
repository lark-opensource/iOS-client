//
//  AWEStickerPickerControllerFavoritePlugin.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/25.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerControllerPluginProtocol.h>
#import "AWEStickerViewLayoutManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPropFavoriteObserverProtocol <NSObject>

@property (nonatomic, nullable, copy) void (^favoriteResultCallback)(BOOL result, IESEffectModel *willFavoriteProp, BOOL isFavorite);

@end

/**
 * 我的收藏插件
 */
@interface AWEStickerPickerControllerFavoritePlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, weak) id<AWEStickerViewLayoutManagerProtocol> layoutManager;

@property (nonatomic, copy, nullable) NSDictionary *trackingInfoDictionary;

@property (nonatomic, weak) id <ACCPropFavoriteObserverProtocol> favoriteObserver;

@end

NS_ASSUME_NONNULL_END
