//
//  MVPBaseServiceContainer+DVEInject.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/2/15.
//

#import "MVPBaseServiceContainer.h"
#import <NLEEditor/DVEVCContextExternalInjectProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEResourceLoader: NSObject<DVEResourceLoaderProtocol>
@end

@interface DVELiteEditorInjectionImpl: NSObject<DVELiteEditorInjectionProtocol>
@end

@interface DVEBottomView: UIButton<DVELiteBottomFunctionalViewActionProtocol>
@end

@interface VEResourceCategoryModel : NSObject<DVEResourceCategoryModelProtocol>
@end

@interface VEResourceModel : NSObject<DVEResourceModelProtocol>

@property (nonatomic, strong) IESEffectModel *model;
@property (nonatomic, assign) BOOL downloading;

@end

@interface MVPBaseServiceContainer (MVPBaseServiceContainer_DVEInject)<DVEVCContextExternalInjectProtocol>
@end

NS_ASSUME_NONNULL_END
