//
//  NSThread+LV.h
//  VideoTemplate
//
//  Created by luochaojing on 2020/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSThread (LV)

+ (void)lv_runOnMain:(void(^)(void))action;

@end

NS_ASSUME_NONNULL_END
