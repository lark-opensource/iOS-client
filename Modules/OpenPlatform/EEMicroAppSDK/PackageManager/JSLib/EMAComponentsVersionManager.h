//
//  EMAComponentsVersionManager.h
//  EEMicroAppSDK
//
//  Created by Limboy on 2020/9/4.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPBaseJSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAComponentsVersionManager : NSObject

/// 开始更新组件（如果有必要）
- (void)updateComponentsIfNeeded;

@end

NS_ASSUME_NONNULL_END
