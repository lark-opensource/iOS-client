//
//  DVEDataCache+LiteEditor.h
//  NLEEditor
//
//  Created by Lincoln on 2022/3/1.
//

#import "DVEDataCache.h"

NS_ASSUME_NONNULL_BEGIN

#define kUserParmLastEditBeautyName @"kUserParmLastEditBeautyName"

@interface DVEDataCache (LiteEditor)

+ (void)lite_setLastEditBeautyName:(NSString *)name;
+ (NSString *)lite_lastEditBeautyName;

@end

NS_ASSUME_NONNULL_END
