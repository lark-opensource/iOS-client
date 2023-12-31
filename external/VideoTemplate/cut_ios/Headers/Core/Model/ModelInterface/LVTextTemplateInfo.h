//
//  LVTextTemplateInfo.h
//  VideoTemplate
//
//  Created by Nemo on 2020/10/12.
//

#import <Foundation/Foundation.h>
#import "LVGeometry.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVTextTemplateSubInfo : NSObject

@property (nonatomic, copy, readonly) NSString *text;
//相对于模版的时间范围
@property (nonatomic, assign, readonly) CMTimeRange timeRange;
@property (nonatomic, assign, readonly) LVTranslation translation;
@property (nonatomic, assign, readonly) CGSize normalizSize;
@property (nonatomic, assign, readonly) NSUInteger index;

@end

@interface LVTextTemplateInfo : NSObject

@property (nonatomic, assign, readonly) CMTimeRange targetTimeRange;
@property (nonatomic, assign, readonly) CGFloat rotation;
@property (nonatomic, assign, readonly) LVScale scale;
@property (nonatomic, assign, readonly) LVTranslation translation;
@property (nonatomic, assign, readonly) CGSize normalizSize;
@property (nonatomic, copy, readonly) NSArray<LVTextTemplateSubInfo *> *textInfos;

- (instancetype)initWithJson:(NSDictionary <NSString *, id> *)jsonDic;

@end

NS_ASSUME_NONNULL_END
