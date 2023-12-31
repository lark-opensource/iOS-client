//
//  AWEVideoEffectChooseSimplifiedCellModel.h
//  Indexer
//
//  Created by Daniel on 2021/11/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@interface AWEVideoEffectChooseSimplifiedCellModel : NSObject

@property (nonatomic, strong, nullable) IESEffectModel *effectModel;
@property (nonatomic, assign) AWEEffectDownloadStatus downloadStatus;

- (AWEEffectDownloadStatus)getNextStatus;

@end
