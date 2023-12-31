//
//  ACCNLEBundleResource.h
//  Aweme
//
//  Created by raomengyun on 2021/11/9.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEBundleDataSource.h>
#import <NLEPlatform/NLEInterface.h>

@interface ACCNLEBundleResource : NSObject<NLEBundleDataSource>

@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary<NSString *, AVAsset *> *videoResourceUUIDs;
@property (nonatomic, strong, nonnull, readonly) NSMutableDictionary<NSString *, AVAsset *> *audioResourceUUIDs;

@property (nonatomic, weak, nullable) NLEInterface_OC *nle;

@end

@interface NLEInterface_OC(BundleResource)

@property (nonatomic, strong, nonnull, readonly) ACCNLEBundleResource *acc_bundleResource;

- (BOOL)acc_slot:(nonnull NLETrackSlot_OC *)slot isRelateWithAsset:(nonnull AVAsset *)asset;

- (void)acc_appendBundleResourceFrom:(nonnull NLEInterface_OC *)nle;

@end
