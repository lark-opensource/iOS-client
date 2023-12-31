//
//  CJMetaSecDelegate.h
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#ifndef CJMetaSecDelegate_h
#define CJMetaSecDelegate_h

@protocol CJMetaSecDelegate <NSObject>

- (void)reportForScene:(NSString *)scene;

@optional
- (void)registerScenePageNameCallback:(NSInteger)biz cb:(nonnull id)cb;

@end

#endif /* CJMetaSecDelegate_h */
