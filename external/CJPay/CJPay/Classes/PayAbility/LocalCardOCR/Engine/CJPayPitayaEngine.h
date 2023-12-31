//
//  CJPayPitayaEngine.h
//  cjpay_ocr_optimize
//
//  Created by ByteDance on 2023/5/9.
//

#import <Foundation/Foundation.h>

#ifndef CJPayPitayaEngine_h
#define CJPayPitayaEngine_h

@class PTYTaskData;
@class PTYPackage;
typedef void (^CJPayPitayaEngineRunCallback)(BOOL success, NSError * _Nullable error, PTYTaskData * _Nullable output, PTYPackage * _Nullable package);
typedef void (^CJPayPitayaEngineCallback)(BOOL success, NSError * _Nullable error, PTYPackage * _Nullable package);

@interface CJPayPitayaEngine : NSObject

+ (instancetype)sharedPitayaEngine;

- (void)initPitayaEngine:(NSDictionary *_Nullable)params appId:(NSString* _Nullable)appId appVersion:(NSString *_Nullable)appVersion;

- (void)start:(void (^)(BOOL success, NSError *_Nullable error))callback;

- (BOOL)hasInitPitaya;

- (BOOL)isPitayaReady;

- (void)requestPacket:(NSString *)bussiness download:(BOOL)download callback:(CJPayPitayaEngineCallback)callback;

- (void)requestPacketAll;

- (void)queryPacket:(NSString*)bussiness callback:(CJPayPitayaEngineCallback)callbak;

- (void)downloadPacket:(NSString*)bussiness callbakc:(CJPayPitayaEngineCallback)callback;

- (void)runPacket:(NSString *)bussiness params:(NSDictionary*)params runCallback:(CJPayPitayaEngineRunCallback)callback async:(BOOL)async;

- (void)registerMessageHandler:(NSString *)business handler:(NSDictionary *(^)(NSDictionary *message))handler;

- (void)removeMessageHandler:(NSString *)business;

- (void)registerAppLogRunEvent:(NSString *)business callback:(CJPayPitayaEngineRunCallback)callback;

- (void)removeAppLogEvent:(NSString *)business;

@end

#endif /* CJPayPitayaEngine_h */
