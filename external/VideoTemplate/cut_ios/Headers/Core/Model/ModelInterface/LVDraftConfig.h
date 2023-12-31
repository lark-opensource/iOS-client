//
//  LVDraftConfig.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDefinition.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

//@interface LVDraftConfig : MTLModel <MTLJSONSerializing, LVCopying>

@interface LVDraftConfig (Interface)

/**
 视频是否一键静音
 */
@property (nonatomic, assign) BOOL videoMuted;

/**
 记录录音自增序号的最后值，默认值1
 */
//@property (nonatomic, assign) NSInteger recordAudioLastIndex;

/**
 记录提取音乐自增序号的最后值，默认值1
 */
//@property (nonatomic, assign) NSInteger extractAudioLastIndex;

/**
 字幕识别的task_id
 */
//@property (nonatomic, copy) NSString *subtitleRecognitionID;

/**
 歌词识别的task_id
 */
//@property (nonatomic, copy) NSString *lyricsRecognitionID;

/**
 字幕编辑是否”同步样式位置到其他字幕“
 */
//@property (nonatomic, assign) BOOL subtitleSync;

/**
 歌词编辑是否“b同步样式位置到其他歌词”
 */
//@property (nonatomic, assign) BOOL lyricsSync;

/**
贴纸当前最大层级
*/
//@property (nonatomic, assign) NSInteger stickerMaxIndex;

/**
全局调节自增序号
*/
//@property (nonatomic, assign) NSInteger adjustMaxIndex;


@end

NS_ASSUME_NONNULL_END
