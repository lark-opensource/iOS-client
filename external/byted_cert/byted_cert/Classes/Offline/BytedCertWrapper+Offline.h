//
//  BytedCertWrapper+Offline.h
//  AFgzipRequestSerializer
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/10.
//

#import "BytedCertWrapper.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertWrapper (Offline)

///  @param params 参数，key定义如下，可以直接使用:
///   BytedCertParamAppId: app id
- (void)doOfflineFaceLivenessWithParams:(NSDictionary *_Nullable)params
                               callback:(BytedCertFaceLivenessResultBlock)callback DEPRECATED_MSG_ATTRIBUTE("请使用BytedCertManager");
//#endif
@end

NS_ASSUME_NONNULL_END
