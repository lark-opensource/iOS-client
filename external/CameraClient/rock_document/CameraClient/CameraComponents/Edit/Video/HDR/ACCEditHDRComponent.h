//
//  ACCEditHRDComponent.h
//  Pods
//
//  Created by 郝一鹏 on 2019/9/25.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>
#import "ACCDraftResourceRecoverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditHDRComponent : ACCFeatureComponent<ACCDraftResourceRecoverProtocol>

- (void)handleAlgorithmCheckFinishedWithScene:(int)scene maxCacheSize:(NSInteger)maxCacheSize;

- (void)handleHDRStatus:(BOOL)hdrOn useOneKey:(BOOL)useOneKey useOpt:(BOOL)useOpt scene:(int)scene modelName:(NSString *)modelName useDenoise:(BOOL)useDenoise asfMode:(NSInteger)asfMode hdrMode:(NSInteger)hdrMode;

@end

NS_ASSUME_NONNULL_END
