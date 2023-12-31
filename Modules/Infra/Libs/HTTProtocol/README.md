# HTTProtocol

基本的HTTP导流框架，具体实现需要注入

## Install

Podfile中添加repo源: `source 'git@code.byted.org:ee/pods_specs.git'`
然后在集成的target上添加: `pod 'HTTProtocol'`

## 使用方法
继承扩展BaseHTTProtocol, WKBaseHTTPHandler. 参考LarkRustHTTP

## 其它注意事项
test代码主要在`LarkRustHTTP`库中
