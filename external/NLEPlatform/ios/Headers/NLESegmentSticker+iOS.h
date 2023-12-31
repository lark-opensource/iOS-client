//
//  NLESegmentSticker+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/8.
//

#import <Foundation/Foundation.h>
#import "NLESegmentTransition+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLEStyStickerAnimation+iOS.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentSticker_OC : NLESegment_OC

/// 贴纸透明度
@property (nonatomic, assign) float alpha;

/// 文本内容, 气温，位置，天气 ... json array string : [xxx, xxx, xxx, xxx]
@property (nonatomic, copy) NSString* effectInfo;

/// 贴纸动画
@property (nonatomic, strong) NLEStyStickerAnimation_OC *stickerAnimation;

- (void)setInfoStringList:(NSMutableArray<NSString *> *)infoStringList;

- (NSMutableArray<NSString *> *)getInfoStringList;

- (NLEResourceType)getType;

@end

NS_ASSUME_NONNULL_END
