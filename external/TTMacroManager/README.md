# TTMacroManager

## 问题背景

在 pod 库预编译时，如果业务团队试用了宏判断，将会导致编译产物过早的确定。

比如如下代码：

```objc
#if DEBUG
  NSAssert(...);
#endif
```

它在 Debug 和 Release 等不同模式下的表现是截然不同的，但在预编译时，我们只能选择 Debug 或者 Release，这就导致以后编译模式动态改变的时候，已经编译好的库无法动态调整了。

## 解决方案

解决问题的方案是把宏判断相关的代码抽离出来，不参与预编译，比如判断是否处于 Debug 模式，代码可以这样写：

```objc
// TTMacroManager.h

#import <Foundation/Foundation.h>

@interface TTMacroManager : NSObject

+ (BOOL)isDebug;

@end

// TTMacroManager.m
#import "TTMacroManager.h"

@implementation TTMacroManager

+ (BOOL)isDebug {
#if DEBUG
    return YES;
#else
    return NO;
#endif
}

@end
```

使用者可以这样写：

```objc
#import "TTMacroManager.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([TTMacroManager isDebug]) {
        NSLog(@"isDebug");
    }
    else {
        NSLog(@"noDebug");
    }
}
```
