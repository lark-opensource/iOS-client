//
//  TTKitchenJSONModelizer.h
//  TTKitchen
//
//  Created by 李琢鹏 on 2019/5/27.
//

#import <Foundation/Foundation.h>
#import "TTKitchenManager.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN


/**
 使用 JSONModel 作为 modelizer.
 */
@interface TTKitchenJSONModelizer : NSObject<TTKitchenModelizer>

@end


/**
 使用 TTKitchen 管理的 settings model 需要继承子自这个类。
 */
@interface TTKitchenJSONModel : JSONModel

@end

NS_ASSUME_NONNULL_END
