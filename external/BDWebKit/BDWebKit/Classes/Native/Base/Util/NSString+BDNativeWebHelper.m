//
//  NSString+BDNativeWebHelper.m
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/7/8.
//

#import "NSString+BDNativeWebHelper.h"

@implementation NSString (BDNativeHelper)

- (NSArray *)bdNativeJSONArray {
    NSArray* o = [self bdNativeJSONObject];
    if (![o isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return o;
}

- (NSDictionary *)bdNativeJSONDictionary {
    NSDictionary* o = [self bdNativeJSONObject];
    if (![o isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return o;
}

- (NSMutableDictionary *)bdNativeMutableJSONDictionary {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:[self bdNativeJSONDictionary]];
    return mutableDic;
}

- (id)bdNativeJSONObject {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    return obj;
}

//func
- (NSArray <NSString *>*)bdNative_nativeDivisionKeywords
{
    //初始化一个mutable集合用作接受每一个关键词
    NSMutableArray <NSString *>*arrM = NSMutableArray.array;
    //判断字符串内是否含有空格符
    if ([self containsString:@" "]) {
        //初始化一个可变字符串用于拼接单个字符
        NSMutableString *cm = NSMutableString.string;
        //遍历字符串内每一个字符
        for (NSInteger i = 0; i < self.length; i++) {
            //当前字符
            NSString *c = [self substringWithRange:NSMakeRange(i, 1)];
            //如果不是空格
            if (![c isEqualToString:@" "]) {
                //则拼接起来
                [cm appendString:c];
            } else {
                //如果下一个是空格并且可变字符串有值，添加元素
                if (![cm containsString:@" "] && cm.length) [arrM addObject:cm];
                //重新初始化可变字符串
                cm = NSMutableString.string;
            }
        }
        //遍历结束，可变字符串可能还包含分割的最后一段关键词，执行同样操作
        if (![cm containsString:@" "] && cm.length) [arrM addObject:cm];
    } else {
        //字符串不包含空格符，直接返回包含一个自身为元素的字符串数组
        arrM = [NSMutableArray arrayWithArray:@[self]];
    }
    //return
    return arrM.copy;
}
@end
