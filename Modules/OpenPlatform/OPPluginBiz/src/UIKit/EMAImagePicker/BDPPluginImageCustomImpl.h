//
//  BDPPluginImageCustomImpl.h
//  Pods
//
//  Created by zhangkun on 18/07/2018.
//

#import <Foundation/Foundation.h>
#import <OPPluginBiz/BDPChooseImageDefine.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Image
#pragma mark -
/****************************************************************************/
/*********                       Image                       ****************/
/****************************************************************************/

@class BDPChooseImagePluginModel;

@interface BDPPluginImageCustomImpl : NSObject

+ (instancetype)sharedPlugin;

/// 选择图片
/// @param model 提供给上层的数据model
/// @param completion 返回选择图片(支持多个)的回调(images 为 nil 且 type 为 pass 代表用户取消)
///
- (void)bdp_chooseImageWithModel:(BDPChooseImagePluginModel * _Nonnull)model
                  fromController:(UIViewController * _Nullable)fromController
                      completion:(void (^ _Nonnull)(NSArray<UIImage *> * _Nullable images, BOOL isOriginal, BDPImageAuthResult authResut))completion;

@end

NS_ASSUME_NONNULL_END
