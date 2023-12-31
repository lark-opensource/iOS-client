//
//  CJPayMetaSecManager.h
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#import <Foundation/Foundation.h>
#import "CJMetaSecDelegate.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMetaSecManager : NSObject

@property (nonatomic, strong) id<CJMetaSecDelegate> delegate;

+ (instancetype)defaultService;

- (void)reportForSceneType:(CJPayRiskMsgType)sceneType;
- (void)reportForScene:(NSString *)scene;
- (void)registerScenePageNameCallback:(NSInteger)biz cb:(id)cb;

@end

NS_ASSUME_NONNULL_END
