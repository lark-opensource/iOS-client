//
//  ALAssetsLibrary+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/3.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef void(^EMASaveImageCompletion)(NSError* error);

@interface ALAssetsLibrary (EMA)

/**
 请存gif图使用该方法

 @param imgData 图片的imageData，注意要符合格式
 */
- (void)ema_saveImageData:(NSData *)imgData window:(UIWindow * _Nullable)window;
- (void)ema_saveImage:(UIImage *)img window:(UIWindow * _Nullable)window;
- (void)ema_saveImage:(UIImage *)img toAlbum:(NSString *)albumName withCompletionBlock:(EMASaveImageCompletion)completionBlock;

+ (UIImage *)ema_getBigImageFromAsset:(ALAsset *)asset;

@end
