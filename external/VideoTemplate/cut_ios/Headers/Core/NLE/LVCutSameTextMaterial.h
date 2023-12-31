//
//  LVCutSameTextMaterial.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/24.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameTextMaterial : NSObject

@property (nonatomic, copy, readonly) NSString *materialId;     // 文字的ID
@property (nonatomic, copy, readonly) NSString *slotId;
@property (nonatomic, copy) NSString *content;       // 文字内容
@property (nonatomic, assign) CMTimeRange targetTimeRange; // 时间范围


@end

NS_ASSUME_NONNULL_END
