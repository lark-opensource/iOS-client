//
//  LVDraftImagePayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

//@interface LVDraftImagePayload : LVDraftPayload
//@property (nonatomic, assign) NSInteger height;
//@property (nonatomic, assign) NSInteger initialScale;
//@property (nonatomic, copy)   NSString *path;
//@property (nonatomic, assign) NSInteger width;
//@end

@interface LVDraftImagePayload(Interface) // : LVDraftPayload

/**
 文件路径+名称
 */
//@property (nonatomic, copy) NSString *path;

/**
 图像宽
 */
//@property (nonatomic, assign) NSInteger width;

/**
 图像高
 */
//@property (nonatomic, assign) NSInteger height;

/**
 初始放大系数
 */
//@property (nonatomic, assign) CGFloat initialScale;

- (void)convertImageIfNeededWithRootPath:(NSString *)rootPath;

@end

NS_ASSUME_NONNULL_END
