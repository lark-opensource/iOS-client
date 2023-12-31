//
//  BDUGShareActivityDataModel.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/15.
//

#import <Foundation/Foundation.h>

@interface BDUGShareActivityOriginDataModel : NSObject

/**
 面板ID
 */
@property (nonatomic, copy) NSString *panelId;

/**
 资源ID
 */
@property (nonatomic, copy) NSString *resourceId;

/**
 分享URL，如果是网页链接形式的分享需要传的参数。
 */
@property (nonatomic, copy) NSString *shareUrl;
//todo: url -> URLString

/**
 业务方如果有特殊需求，比如有其他字段需要UG做处理时，可与后台接口协商后添加到extro中。如果没有特殊需求可忽略。
 */
@property (nonatomic, strong) NSDictionary *extroData;

@end

@interface BDUGShareActivityExtroDataModelForDefaultStrategy : NSObject

@end


