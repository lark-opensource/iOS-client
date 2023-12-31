//
//  HMDUIFrozenDetectProtocol.h
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDUIFrozenDetectProtocol <NSObject>
@required
- (void)didDetectUIFrozenWithData:(NSDictionary *)data;
@end

NS_ASSUME_NONNULL_END
