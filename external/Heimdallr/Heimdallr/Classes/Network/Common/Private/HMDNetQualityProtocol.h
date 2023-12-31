//
//  HMDNetQualityProtocol.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/4.
//

#ifndef HMDNetQualityProtocol_h
#define HMDNetQualityProtocol_h

@protocol HMDNetQualityProtocol <NSObject>

- (void)hmdCurrentNetQualityDidChange:(NSInteger)netQualityType;

@end

#endif /* HMDNetQualityProtocol_h */
