//
//  ADFGLoadResource.h
//  ADFeelGoodSDK
//
//  Created by bytedance on 2020/8/27.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^imageBlock)(UIImage* _Nullable image);
/// 同步方式
extern UIImage* _Nullable ADFG_compatImageWithName(NSString * _Nullable imageName);
/// 异步方式
extern void  ADFG_async_compatImageWithName(NSString *_Nullable imageName,imageBlock _Nullable block);
NS_ASSUME_NONNULL_END
