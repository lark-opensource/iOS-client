//
//  HMDMetricKitSegmentRenameFix.h
//  Pods
//
//  Created by ByteDance on 2023/8/16.
//

#import <Foundation/Foundation.h>

typedef void (^ _Nullable HMDMetricKitFixedCallBack) (void);

#ifndef HMDMetricKitSegmentRenameFix_h
#define HMDMetricKitSegmentRenameFix_h

API_AVAILABLE(ios(14.0), macos(12.0))
@interface HMDMetricKitSegmentInfo : NSObject

@property(nonatomic, strong, nonnull) NSString *binaryName;

@property(nonatomic, strong, nonnull) NSString *binaryUUID;

@property(nonatomic, assign) uintptr_t startAddressBinaryTextSegment;

@property(nonatomic, assign) uintptr_t endAddressBinaryTextSegment;

@property(nonatomic, assign) uintptr_t anchorPoint;

@end


API_AVAILABLE(ios(14.0), macos(12.0))
@interface HMDMetricKitSegmentRenameFix : NSObject

@property(nonatomic, strong) HMDMetricKitFixedCallBack callback;

+ (instancetype _Nonnull)shared;

- (BOOL)removeExpendDir API_AVAILABLE(ios(14.0));

/** eg.
 "AppBinaryMap": {
         "AWEIMFramework": "0a2c5debc9c933f2b35e10f95971fbdc",
         "AWESearchFramework": "b0a990cddd1c3b3db669ba199da96f9b",
         "Aweme": "0fec82e570263352a61ff3d72f649dd2",
         "AwemeCore": "80e4456d62783c6b9116dc486b4c6b94",
         "BDLRepairer": "cf8fc127af613d759f59b4bc14af644f",
         "EffectSDKFramework": "09e20d389cbf31fbaa9512b67b38ca77",
         "RealXBase": "62e4f01ce0233817b57c5dc641c73691",
         "TTFFmpegFrameworkA": "44e72629c94b3e76aa40c0c3430ebb6f",
         "VolcEngineRTC": "37ebf7f5c0093daa8c8d554f10c1fb6e",
         "boringssl": "13425e1af10c336cbdb5a303a36907c8",
         "byteaudio": "0fdedcd680a238389e8e5d424b245e5b",
         "isecgm": "70643cb5a1da3885a6e88168ca73cd91",
         "libobjc-trampolines.dylib": "7e77fc541c3331c086e81fb7bf12836c",
         "libvcn": "18edca37388637d492a0975d282a56be"
     }
 */
- (NSDictionary * _Nullable)fetchCurrentImageNameUUIDMap;

/** eg.
 "RecentAppImage": {
         "258019": {
             "BinaryName": "Aweme",
             "MainAddress": 544913608,
             "UUID": "0fec82e570263352a61ff3d72f649dd2"
         }
     }
 */
- (NSDictionary * _Nullable)fetchRecentAppVersionMainOffset;

/** eg.
 "history_app_image_info": {
         "4875319496": [
             {
                 "binaryName": "Aweme",
                 "binaryUUID": "0fec82e570263352a61ff3d72f649dd2",
                 "endAddressBinaryTextSegment": 4329635840,
                 "startAddressBinaryTextSegment": 4329570304
             },
 */
-(NSDictionary * _Nullable)historyAppImageTextSegmentMap;

-(void)resetAppImagesTextSegmentRangeFile;

/** eg.
 "history_pre_app_image_info": {
         "4875319496": [
             {
                 "binaryName": "Aweme",
                 "binaryUUID": "0fec82e570263352a61ff3d72f649dd2",
                 "endAddressBinaryTextSegment": 4329635840,
                 "startAddressBinaryTextSegment": 4329570304
             },
 */
-(NSDictionary * _Nullable)historyPreAppImageTextSegmentMap;

//get __TEXT and __BD_TEXT segment range for all app images.
- (void)asyncRecordRecordAppImagesTextSegmentInfo;

//record your segment info fast.
- (void)asyncPreRecordAppImagesTextSegmentInfo:(HMDMetricKitSegmentInfo * _Nonnull)info __attribute__((deprecated("deprecated. Asynchronous operations are unreliable.")));

//record your segment info fast.
- (void)preRecordAppImagesTextSegmentInfo:(HMDMetricKitSegmentInfo * _Nonnull)info;

@end



#endif /* HMDMetricKitSegmentRenameFix_h */
