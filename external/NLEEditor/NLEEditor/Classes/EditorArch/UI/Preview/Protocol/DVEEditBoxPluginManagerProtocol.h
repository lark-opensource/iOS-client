//
//  DVEEditBoxPluginManagerProtocol.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/18.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEEditBoxPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DVEEditBoxPluginType) {
    DVEEditBoxPluginTypeSticker,//贴纸，信息化贴纸和图片贴纸为一个类型的轨道
    DVEEditBoxPluginTypeText,//文本，有自己单独的轨道
};

@protocol DVEEditBoxPluginManagerProtocol <DVECoreProtocol>

- (nullable id<DVEEditBoxPluginProtocol>)editBoxPluginWithType:(DVEEditBoxPluginType)type;

@end

NS_ASSUME_NONNULL_END
