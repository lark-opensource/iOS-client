//
//  LVDraftPlaceholderPayload.h
//  LVTemplate
//
//  Created by iRo on 2019/12/4.
//

#import "LVDraftPayload.h"

NS_ASSUME_NONNULL_BEGIN


//@interface LVDraftPlaceholderPayload : LVDraftPayload
@interface LVDraftPlaceholderPayload(Interface)
/**
 占位名称
 */
//@property (nonatomic, copy, nonnull) NSString *name;

/**
 初始化占位资源
 
 @param name 占位名称
 @param type 资源类型
 @return 占位实例
 */
- (instancetype)initWithType:(LVPayloadRealType)type name:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
