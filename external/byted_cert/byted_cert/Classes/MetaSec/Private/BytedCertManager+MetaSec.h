//
//  BytedCertManager+MetaSec.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/6/28.
//

#import "BytedCertManager.h"

NS_ASSUME_NONNULL_BEGIN


@interface BytedCertManager (MetaSec)

+ (void)metaSecReportForBeforCameraStart;
+ (void)metaSecReportForOnCameraRunning;

@end

NS_ASSUME_NONNULL_END
