//
//  AWEVideoEffectPathBlockManager.h
//  Indexer
//
//  Created by Daniel on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <TTVideoEditor/IESMMBaseDefine.h>

@class AWEVideoPublishViewModel;

typedef IESMMEffectStickerInfo * (^AWEEffectPlatformPathBlock)(NSString *effectPathId, IESEffectFilterType effectType);

@interface AWEVideoEffectPathBlockManager : NSObject

/// pathConvertBlock
/// @param publishModel 用来判断是否是单图视频
+ (AWEEffectPlatformPathBlock)pathConvertBlock:(AWEVideoPublishViewModel *)publishModel;

@end
