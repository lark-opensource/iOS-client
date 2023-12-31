//
//  NLETemplateVolumeUtils+iOS.h
//  NLEPlatform
//
//  Created by Lemonior on 2021/10/27.
//

#import <Foundation/Foundation.h>
#import "NLETemplateModel+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETemplateVolumeUtils_OC : NSObject

/**
 * 获取当前模板音乐是否可调节
 */
+ (BOOL)templateMutableItemVolumeEnable:(NLETemplateModel_OC *)templateModel;
/**
 * 更新模板音乐可调节状态
 */
+ (void)updateTemplateMutableItem:(NLETemplateModel_OC *)templateModel withVolumeEnableStatus:(BOOL)isEnabled ;

@end

NS_ASSUME_NONNULL_END
