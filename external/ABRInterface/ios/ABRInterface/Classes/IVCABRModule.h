//
//  IVCABRModule.h
//  test
//
//  Created by guikunzhi on 2020/3/29.
//  Copyright © 2020 gkz. All rights reserved.
//

#ifndef IVCABRModule_h
#define IVCABRModule_h

#import <Foundation/Foundation.h>
#import "IVCABRPlayStateSupplier.h"
#import "IVCABRStream.h"
#import "IVCABRInfoListener.h"
#import "IVCABRDeviceInfo.h"
#import "VCABRConfig.h"
#import "VCABRResult.h"

typedef NS_ENUM(int, ABRFlowAlgoType) {
    ABRFlowAlgoTypeBABBFlow = 0,
    ABRFlowAlgoTypeBBFlow = 1,
    ABRFlowAlgoTypeMPCFlow = 2,
    ABRFlowAlgoTypeBWFlow = 3,
    ABRFlowAlgoTypeCSFlow = 4,
    ABRFlowAlgoTypeRLFlow = 5,
    ABRFlowAlgoTypeBolaFlow = 6,
    ABRFlowAlgoTypeFestiveFlow = 7,
    ABRFlowAlgoTypeMPC2Flow = 8,
    ABRFlowAlgoTypeBBAFlow = 9,
};

typedef NS_ENUM(int, ABROnceAlgoType) {
    ABROnceAlgoTypeB2BModel = 0,
    ABROnceAlgoTypeBABBOnce = 1,
    ABROnceAlgoTypeBwOnce = 2,
    ABROnceAlgoTypeCSOnce = 3,
};

typedef NS_ENUM(int, ABRSelectScene) {
    ABRSelectScenePreload = 0,
    ABRSelectSceneStartUp = 1
};

typedef NS_ENUM(NSInteger, ABRPredictAlgoType) {
    ABRPredictAlgoTypeBABB = 0,
    ABRPredictAlgoTypeBB = 1,
    ABRPredictAlgoTypeMPC = 2,
    ABRPredictAlgoTypeBW = 3,
    ABRPredictAlgoTypeCS = 4,
    ABRPredictAlgoTypeRL = 5,
    ABRPredictAlgoTypeBOLA = 6,
    ABRPredictAlgoTypeFESTIVE = 7,
    ABRPredictAlgoTypeMPC2 = 8,
};

typedef NS_ENUM(NSInteger, ABRStreamType) {
    ABRStreamTypeVideo = 0,
    ABRStreamTypeAudio = 1
};

typedef NS_ENUM(NSInteger, ABRNetworkState) {
    ABRNetworkStateUnknow = -1,
    ABRNetworkStateWifi = 0,
    ABRNetworkState4G = 1
};

typedef NS_ENUM(NSInteger, ABRUseCacheMode) {
    ABRNotUseCache = 0,
    ABRDefaultUseCache = 1,
    ABRStrictUseCache = 2
};

@protocol IVCABRModule <NSObject>

- (void)configWithParams:(nullable id<IVCABRPlayStateSupplier>)playStateSupplier;
- (void)setMediaInfo:(nullable NSArray<NSObject <IVCABRVideoStream> *> *)videoStreamList withAudio:(nullable NSArray< NSObject <IVCABRAudioStream> *> *)audioStreamList;
- (void)setDeviceInfo:(nullable id<IVCABRDeviceInfo>)deviceInfo;
- (void)setInfoListener:(nullable id<IVCABRInfoListener>)infoListener;
- (nullable VCABRResult *)onceSelect:(ABROnceAlgoType)onceType scene:(ABRSelectScene)scene;
- (nullable VCABRResult *)getPredict;
- (void)start:(ABRFlowAlgoType)flowType intervalMs:(int)intervalMs;
- (void)stop;
- (void)setIntValue:(int)value forKey:(int)key;
- (void)setLongValue:(int64_t)value forKey:(int)key;
- (void)setFloatValue:(float)value forKey:(int)key;
- (void)setDoubleValue:(double)value forKey:(int)key;
- (void)setStringValue:(NSString *)value forKey:(int)key;
- (void)addBufferInfo:(ABRStreamType)streamType
            streamKey:(NSString *_Nonnull)streamKey
              bitrate:(int64_t)bitrate
            availSize:(int64_t)availSize
             headSize:(int64_t)headeSize;

@end

#endif /* IVCABRModule_h */
