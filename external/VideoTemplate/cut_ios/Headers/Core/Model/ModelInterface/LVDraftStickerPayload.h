//
//  LVDraftStickerPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"

NS_ASSUME_NONNULL_BEGIN

//@interface LVDraftStickerPayload : LVDraftPayload
@interface LVDraftStickerPayload(Interface)


/*
 @property (nonatomic, copy)           NSString *categoryID;
 @property (nonatomic, copy)           NSString *categoryName;
 @property (nonatomic, nullable, copy) NSString *iconUrl;
 @property (nonatomic, copy)           NSString *name;
 @property (nonatomic, copy)           NSString *path;
 @property (nonatomic, nullable, copy) NSString *previewCoverUrl;
 @property (nonatomic, copy)           NSString *resourceID;
 @property (nonatomic, copy)           NSString *stickerID;
 @property (nonatomic, copy)           NSString *unicode;
 */

///**
// 贴纸的标识
// */
//@property (nonatomic, copy, nonnull) NSString *stickerID;

/**
 资源唯一标识
 */
//@property (nonatomic, copy, nonnull) NSString *resourceID;

/**
 贴纸名字
 */
//@property (nonatomic, copy, nonnull) NSString *name;

/**
 文件路径，注意：这个路径应该是草稿目录下的相对路径
 */
@property (nonatomic, copy, nonnull) NSString *relativePath;

/**
 贴纸icon
 */
//@property (nonatomic, copy, nullable) NSString *iconUrl;

/**
 贴纸效果预览图
 */
//@property (nonatomic, copy, nullable) NSString *previewCoverUrl;

/**
 贴纸分类id
 */
//@property (nonatomic, copy, nullable) NSString *categoryID;

/**
 贴纸分类名字
 */
//@property (nonatomic, copy, nullable) NSString *categoryName;

/**
 初始放大系数
 */
@property (nonatomic, assign) CGFloat initialScale;

/**
 资源的MD5值
 */
@property (nonatomic, copy, nullable) NSString *resourceMD5;

/**
 emoji的Unicode，优先用emoji再用path
 */
@property (nonatomic, copy) NSString *emojiUnicode;

/**
 图片贴纸
 */
- (void)convertImageIfNeededWithRootPath:(NSString *)rootPath;

@end

NS_ASSUME_NONNULL_END
