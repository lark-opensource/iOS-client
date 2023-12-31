# BDDataDecoratorTob

AppLog to b & 私有化加解密库

# 要求

- iOS 8.0+
- Xcode 9.0+

# 接入指南

SDK接入二进制版本SDK，二进制经过安全同学的加固混淆，可以防破解。由于Encrypt敏感单词，起了别名BDDataDecoratorTob。


```
  pod 'BDDataDecoratorTob'

```

# API使用

## NSData加密API

提供Objective-C风格接口


```

#import <BDDataDecoratorTob/NSData+DataDecoratorTob.h>


NSData *data = xxx;

NSData *decorated = [data bd_dataByPrivateDecorated];
 if (decorated != nil)
 {
    // 加密成功
 }
 else
 {
    // 加密失败
 }
```


# 版本记录

## 1.0.0


# 组件交流反馈群

[点击加入Lark反馈群](lark://client/chatchatId=6756438850987393288)


