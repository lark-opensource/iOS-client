//
//  HMDZombieObject.h
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import <Foundation/Foundation.h>


BOOL isZombieClass(char * _Nullable name);

// 设置为root class，避免父类存在实现不走消息转发，_NSZombie_也是root class
NS_ROOT_CLASS
@interface HMDZombieObject

@end

