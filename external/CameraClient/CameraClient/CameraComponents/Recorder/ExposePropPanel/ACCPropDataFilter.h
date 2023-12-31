//
//  ACCPropDataFilter.h
//  CameraClient
//
//  Created by Shen Chen on 2020/5/15.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CameraClient/AWEStickerDataManager.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropDataFilter : NSObject
@property (nonatomic, strong) ACCRecordViewControllerInputData *inputData;
@property (nonatomic, assign) BOOL filterCommerce;
@property (nonatomic, assign) AWEStickerFilterType effectFilterType;
- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData;
- (BOOL)allowEffect:(IESEffectModel *)effect;
- (NSArray<IESEffectModel *> *)filteredEffects:(NSArray<IESEffectModel *> *)effects;
@end

NS_ASSUME_NONNULL_END
