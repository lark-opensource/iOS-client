//
//  LVTemplateMigrationProxy.h
//  Pods
//
//  Created by kevin gao on 9/30/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LVTemplateMigrationCheckCallBack)(BOOL needUpgrade, NSDictionary* _Nullable jsonDict, NSError* _Nullable error);
typedef void(^LVTemplateMigrationCompleteCallBack)(NSDictionary* _Nullable jsonDict, NSError* _Nullable error);

/*
 模板
 */
@interface LVTemplateMigrationProxy : NSObject

/*
 执行迁移操作
 */
- (void)migrateDraftWithSourcePath:(NSString*)directory
                        jsonString:(NSString *)jsonString
                          complete:(LVTemplateMigrationCompleteCallBack)completeBlock;

@end

NS_ASSUME_NONNULL_END
