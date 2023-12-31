//
//  NLESegmentSubtitleSticker+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#import <Foundation/Foundation.h>
#import "NLESegmentSticker+iOS.h"

@class NLEStyleText_OC;

/// SRT 歌词贴纸 / 字幕贴纸
@interface NLESegmentSubtitleSticker_OC : NLESegmentSticker_OC

/// srt 文件
@property (nonatomic, strong) NLEResourceNode_OC *srtFile;

/// 歌词贴纸的样式文件
@property (nonatomic, strong) NLEResourceNode_OC *effectSDKFile;

/// 文字样式
@property (nonatomic, strong) NLEStyleText_OC *style;

/// Resource时间坐标-起始点
@property (nonatomic, assign) CMTime timeClipStart;

/// Resource时间坐标-终止点
@property (nonatomic, assign) CMTime timeClipEnd;

/// 同srtFile，歌词贴纸的样式文件
//- (NLEResourceNode_OC *)getResNode; /// 直接用父类的就可以了

@end
