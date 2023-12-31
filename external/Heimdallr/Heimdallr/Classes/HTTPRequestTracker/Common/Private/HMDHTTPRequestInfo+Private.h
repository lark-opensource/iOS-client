//
//  HMDHTTPRequestInfo+Private.h
//  Heimdallr
//
//  Created by liuhan on 2023/10/12.
//

#import "HMDHTTPRequestInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPRequestInfo (Private)

// sample
@property (nonatomic, assign) BOOL isURLInBlockList;
@property (nonatomic, assign) BOOL isURLInAllowedList;
@property (nonatomic, assign) BOOL isSDKURLInAllowedList;
@property (nonatomic, assign) BOOL isHeaderInAllowedList;
@property (nonatomic, assign) BOOL isHitMovingLine;
@property (nonatomic, assign) BOOL isMovingLine;

@end

NS_ASSUME_NONNULL_END
