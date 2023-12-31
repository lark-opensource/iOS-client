//
//  NLETextTemplateInfo.h
//  NLEPlatform
//
//  Created by bytedance on 2021/7/6.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLETextTemplateSubInfo : NSObject

@property (nonatomic, copy, readonly) NSString *text;
//相对于模版的时间范围
@property (nonatomic, assign, readonly) CMTimeRange timeRange;
@property (nonatomic, assign, readonly) CGPoint translation;
@property (nonatomic, assign, readonly) CGSize normalizSize;
@property (nonatomic, assign, readonly) NSUInteger index;

@end

@interface NLETextTemplateInfo : NSObject

@property (nonatomic, assign, readonly) CMTimeRange targetTimeRange;
@property (nonatomic, assign, readonly) CGFloat rotation;
@property (nonatomic, assign, readonly) CGPoint scale;
@property (nonatomic, assign, readonly) CGPoint translation;
@property (nonatomic, assign, readonly) CGSize normalizSize;
@property (nonatomic, copy, readonly) NSArray<NLETextTemplateSubInfo *> *textInfos;

- (instancetype)initWithJson:(NSDictionary <NSString *, id> *)jsonDic;

@end

NS_ASSUME_NONNULL_END
