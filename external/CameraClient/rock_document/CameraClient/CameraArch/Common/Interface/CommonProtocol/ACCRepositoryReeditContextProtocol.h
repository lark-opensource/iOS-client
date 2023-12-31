//
//  ACCRepositoryReeditContextProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/8/31.
//

#import <Foundation/Foundation.h>
@protocol AWEStudioAwemeModelProtocol;

@protocol ACCRepositoryReeditContextProtocol <NSObject>

@optional
/// 从aweme恢复到对应publishmodel的字段
/// @param aweme AWEAwemeModel
- (void)updateFromAweme:(id<AWEStudioAwemeModelProtocol> _Nullable)aweme;
/// 内容是否被修改
- (BOOL)isModified;


@end
