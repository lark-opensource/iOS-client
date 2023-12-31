//
//  ACCCutSameMaterialImportManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import "AWECutSameMaterialAssetModel.h"
#import "ACCCutSameVideoCompressorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameMaterialImportManagerCompletion)(NSArray<AWECutSameMaterialAssetModel *> * _Nullable importAssets, NSError * _Nullable error);

@protocol ACCCutSameMaterialImportManagerProtocol <NSObject>

@property (nonatomic, strong) id<ACCCutSameVideoCompressorProtocol> compressor;

@property (nonatomic, strong) Class<ACCCutSameVideoCompressConfigProtocol> config;

@property (nonatomic, copy) NSString *fillMode;

@property (nonatomic, assign) CGSize outputSize;

- (void)importMaterials:(NSArray<AWECutSameMaterialAssetModel *> *)materials
        progressHandler:(void (^ _Nullable)(CGFloat))progressHandler
             completion:(ACCCutSameMaterialImportManagerCompletion)completion;

- (void)importMaterials:(AWECutSameMaterialAssetModel *)material
      handleCartoonType:(ACCTemplateCartoonType)cartoonType
        handleGameplayAlgorithm:(NSString *)gameplayAlgorithm
        progressHandler:(void (^ _Nullable)(CGFloat))progressHandler
             completion:(ACCCutSameMaterialImportManagerCompletion)completion;

- (void)cancelAll;

- (void)clearCache;

- (NSString *)reproduceImage:(UIImage *)image toPath:(NSString*)draftPath;

- (void)saveResource:(NSArray<AWECutSameMaterialAssetModel *> *)resources outputPath:(NSString *)outputPath toSandboxWithCompletionHandler:(_Nullable ACCCutSameMaterialImportManagerCompletion)handler;

@end

NS_ASSUME_NONNULL_END
