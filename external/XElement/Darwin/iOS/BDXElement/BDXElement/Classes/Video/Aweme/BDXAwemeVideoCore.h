//
//  BDXAwemeVideoCore.h
//  BDXElement
//
//  Created by yuanyiyang on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import "BDXVideoPlayerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXAwemeVideoCore : NSObject <BDXVideoCorePlayerProtocol>

@property (nonatomic, strong) BDXVideoPlayerConfiguration *configuration;
@property (nonatomic, copy) NSDictionary *logExtraDict;
@property (nonatomic, assign) NSTimeInterval actionTimestamp;

@end

NS_ASSUME_NONNULL_END
