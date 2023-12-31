//
//  NLEDownloader_OC.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NLEDownlaoder_OC_h
#define NLEDownlaoder_OC_h

//#import "NLEModel+iOS.h"

@class NLEModel_OC;
namespace cut {
    namespace model {
         class NLEModel;
    }
}

@interface NLEModelDownloaderParams_OC : NSObject

- (instancetype)initWithAppID:(NSString *)appID
                   appVersion:(NSString *)appVersion
             effectSdkVersion:(NSString *)effectSdkVersion
                    accessKey:(NSString *)accessKey
                     platform:(NSString *)platform
                         host:(NSString *)host
               effectCacheDir:(NSString *)effectCacheDir
                modelCacheDir:(NSString *)modelCacheDir
                     deviceId:(NSString *)deviceId
                   deviceType:(NSString *)deviceType;

@end

typedef void(^NLEModelDownloadBlock)(NLEModel_OC *model, NSError *error);
typedef void(^NLEResourceDownloadBlock)(NSString *path, NSError *error);

@interface NLEModelDownloader_OC : NSObject
- (instancetype)initWithParams:(NLEModelDownloaderParams_OC *)params;
- (void)fetchModel:(NLEModel_OC *)model progress:(void(^)(float))progress completion:(NLEModelDownloadBlock)completion;

- (void)fetchResource:(NSString *)davinciResourceId completion:(NLEResourceDownloadBlock)completion;

@end

#endif /* NLEModel_OC_h */
