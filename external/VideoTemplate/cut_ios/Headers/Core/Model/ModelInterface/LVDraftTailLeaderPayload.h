//
//  LVDraftTailLeaderPayload.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import "LVDraftVideoPayload.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN
/**
 片尾素材解析模型
 */

@interface LVDraftTailLeaderPayload(Interface)

//@interface LVDraftTailLeaderPayload : LVDraftVideoPayload
/*
 @interface LVDraftTailLeaderPayload : LVDraftPayload
 @property (nonatomic, nullable, copy) NSString *text;
 @end
 */
/**
 片尾标题
 */
@property (nonatomic, copy) NSString *title;

/**
 片尾内容
 */
@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *accountID;


/**
 是否隐藏片尾内容
 */
@property (nonatomic, assign) BOOL hiddenContent;

/**
 显示内容
 */
- (NSString *)renderContent;

/**
 是否是默认文本
 */
- (BOOL)isDefaultContent;

- (NSString *)accountInfoRenderContent;

- (BOOL)hasAccountInfo;

@end

NS_ASSUME_NONNULL_END
