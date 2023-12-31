//
//  HMDConfigDataProcessor.h
//  Heimdallr
//
//  Created by Nickyo on 2023/4/27.
//

#import <Foundation/Foundation.h>
#import "HMDConfigDataProcessProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDConfigDataProcessor : NSObject <HMDConfigDataProcess>

@property (nullable, nonatomic, weak) id<HMDConfigDataProcessDelegate> delegate;
@property (nullable, nonatomic, weak) id<HMDConfigDataProcessDataSource> dataSource;

@end

NS_ASSUME_NONNULL_END
