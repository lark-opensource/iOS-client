//
//  TTKitchen.h
//  Article
//
//  Created by SongChai on 2018/3/28.
//

#import "TTKitchenManager.h"

#if __has_include(<TTKitchen/TTKitchenManager+Swift.h>)
#import <TTKitchen/TTKitchenManager+Swift.h>
#endif
/**
 * 声明方式：
 * 请各业务方自行定义 TT**KitchenConfig 文件
 * .h 声明key，变量一律以“kTTK”开头。
 * 	  如果是settings，value需要和settings一致
 * 	  key支持通过点语法"."实现对嵌套settings配置的解析
 * .m 文件对具体的key声明其含义、类型、默认值
 *    每一个key可以设置freezed，表示是否在内存中不变（下次启动才能改） 
 * 
 *
 * ***************************
 * 调用逻辑：
 * 根据key取String:     -[TTKitchen getString:]
 * 根据key取BOOL:       -[TTKitchen getBOOL:]
 * 根据key取Float: 	   -[TTKitchen getFloat:]
 * 根据key取Int:        -[TTKitchen getInt:]
 * 根据key取Array:      -[TTKitchen getArray:]
 * 根据key取Dictionary: -[TTKitchen getDictionary:]
 *
 * ***************************
 * 开发调试：
 * 打开TTKitchenBrowserViewController，可以查看设置
 * 打开TTKitchenEditorViewController, 可以对单个key进行更改
 */
