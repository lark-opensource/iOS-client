//
//  IESVideoInfoDefaultFormatter.h
//  CameraClient
//
//  Created by geekxing on 2020/4/10.
//

#import <Foundation/Foundation.h>
@class IESVideoInfo;

NS_ASSUME_NONNULL_BEGIN

@interface IESVideoInfoDefaultFormatter : NSObject

@property (nonatomic, copy) NSString *keyPrefix;
- (NSDictionary *)dictWithVideoInfos:(NSArray<IESVideoInfo *> *)videoInfos;

@end

NS_ASSUME_NONNULL_END
