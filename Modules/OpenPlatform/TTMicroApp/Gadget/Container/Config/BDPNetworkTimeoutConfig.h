//
//  BDPNetworkTimeoutConfig.h
//  Timor
//
//  Created by 张朝杰 on 2019/5/30.
//

#import <OPFoundation/BDPBaseJSONModel.h>


@interface BDPNetworkTimeoutConfig : BDPBaseJSONModel

@property (nonatomic, strong) NSNumber *requestTime;
@property (nonatomic, strong) NSNumber *uploadFileTime;
@property (nonatomic, strong) NSNumber *downloadFileTime;
@property (nonatomic, strong) NSNumber *connectSocketTime;

@end

