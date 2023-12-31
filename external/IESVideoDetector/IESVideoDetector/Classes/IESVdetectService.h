//
//  IESVdetectService.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/6/1.
//

#import <Foundation/Foundation.h>
#import "IESVdetectMonitorProtocol.h"
#import "IESVdetectAlogProtocol.h"

#define IES_VDETECT_SERVICE [IESVdetectService defaultService]

NS_ASSUME_NONNULL_BEGIN

@interface IESVdetectService : NSObject

@property (nonatomic, strong, readonly) id<IESVdetectMonitorProtocol> monitorService;
@property (nonatomic, strong, readonly) id<IESVdetectAlogProtocol> alogService;

+ (instancetype)defaultService;
- (void)registerMonitorService:(id<IESVdetectMonitorProtocol>)monitorService;
- (void)registerAlogService:(id<IESVdetectAlogProtocol>)alogService;

@end

NS_ASSUME_NONNULL_END
