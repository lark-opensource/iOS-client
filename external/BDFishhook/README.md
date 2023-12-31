# BDFishhook使用说明  

Gitlab：<https://code.byted.org/iOS_Library/BDFishhook>

字节内部hook 动态库方法的标准库。已经被头条、抖音等App接入。

1. 解决不能正确设置内存权限问题。

2. 用 vm_read_overwrite 替代了直接赋值进行内存写操作，有兜底策略，不会造成崩溃。

3. 继续跟进多线程问题。在没有好的解决方案之前，也只有先保持 fishhook 之前逻辑，别修复第一个bug。

## install

```ruby
pod 'BDFishhook', '~>0.1.1'
# 提供一个开关，默认关闭此功能，需要手动开启。
pod 'BDFishhook', '~>0.2.1'
```

## 使用

### 使用0.1.*版本

```c++
int bd_rebind_symbols(struct bd_rebinding rebindings[], size_t rebindings_nel);

int bd_rebind_symbols_image(void *header,
                         intptr_t slide,
                         struct bd_rebinding rebindings[],
                         size_t rebindings_nel);
```

### 使用0.2.*版本

```c++
// 提供开关，默认关闭此功能，需要手动开启。待iOS14.5验证完毕，会删除此接口
// 开启功能，默认关闭
void open_bdfishhook(void);

void close_bdfishhook(void);

int bd_rebind_symbols(struct bd_rebinding rebindings[], size_t rebindings_nel);

int bd_rebind_symbols_image(void *header,
                         intptr_t slide,
                         struct bd_rebinding rebindings[],
                         size_t rebindings_nel);
```
