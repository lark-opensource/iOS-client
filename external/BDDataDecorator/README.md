# BDDataDecorator

aes加解密库，用于替换原有的sbox混淆加密方法。

# 要求

- iOS 8.0+
- Xcode 9.0+

# 接入指南

SDK接入二进制版本SDK，二进制经过安全同学的加固混淆，可以防破解。由于Encrypt敏感单词，起了别名DataDecorator。


```
  pod 'BDDataDecorator',:subspecs => [
    'Data',
  ]

```

# API使用

## Base加密API

提供 C函数接口，直接对byte进行加密。


```
#import <BDDataDecorator/app_log_aes_e.h>

 void* dataIn = xxx;
 size_t data_size = xxx;

 size_t bufferSize = applog_decorated_buffer_min_size(data_size);
 uint8_t *buffer = malloc(sizeof(uint8_t) * bufferSize);

 applog_decorated(dataIn, data_size, buffer, &bufferSize)
 if (bufferSize > 0)
 {
    // 加密成功，加密数据为 buffer[0 -> bufferSize]
 }
 else
 {
    // 加密失败
 }
 
```



## NSData加密API

提供Objective-C风格接口


```

#import <BDDataDecorator/NSData+DataDecorator.h>


NSData *data = xxx;

NSData *decorated = [data bd_dataByDecorated];
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

## 2.0.0

- 移除SSBox

## 1.0.2

- SDK兼容SSBox和AES加密
- SDK提供统一控制开关

# 组件交流反馈群

[点击加入Lark反馈群](lark://client/chatchatId=6756438850987393288)


