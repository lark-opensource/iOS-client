//
//  BDXToutiaoVideoCore.h
//  TTLynxAdapter
//
//  Created by jiayuzun on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import <XElement/BDXVideoPlayerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXToutiaoVideoCore : NSObject <BDXVideoCorePlayerProtocol>

@property (nonatomic, strong) BDXVideoPlayerConfiguration *configuration;

@property (nonatomic, copy, readwrite) NSDictionary *logExtraDict;
@property (nonatomic, assign, readwrite) NSTimeInterval actionTimestamp;
@property (nonatomic, weak, readwrite) id<BDXVideoCorePlayerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
