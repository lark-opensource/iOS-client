//
//  IESAVAssetDefaultFormatter.h
//  CameraClient
//
//  Created by geekxing on 2020/4/10.
//

#import <Foundation/Foundation.h>
@class AVAsset;

NS_ASSUME_NONNULL_BEGIN

@interface IESAVAssetDefaultFormatter : NSObject

@property (nonatomic, copy) NSString *keyPrefix;
- (NSDictionary *)dictWithAssets:(NSArray<AVAsset *> *)assets;

@end

NS_ASSUME_NONNULL_END
