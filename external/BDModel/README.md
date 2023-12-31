# BDModel

基于YYModel的Model基础库，主要负责JSON与Model直接的互相转化。



## Benchmark

在iOS圈，[针对谁家的JSON序列化方案好用早有争论和结论](https://blog.ibireme.com/2015/10/23/ios_model_framework_benchmark/)。作者是在2015年benchmark的，时隔多年，再次进行benchmark，部分测试结果和引用文章中不一致。

针对安全进行了最常见的类型不匹配测试，业务中最常见的就是String和Number的类型错误：

| 用例                                   | YYModel        | JSONModel      | Mantle                         |
| -------------------------------------- | -------------- | -------------- | ------------------------------ |
| Model属性为String，JSON字段为Number    | ✅ 自动类型转换 | ✅ 自动类型转换 | ❎类型错误，按原类型使用会crash |
| Model属性为Number，JSON字段为String    | ✅ 自动类型转换 | ✅ 自动类型转换 | ❎类型错误，按原类型使用会crash |
| Model属性为NSInteger，JSON字段为String | ✅ 自动类型转换 | ✅ 自动类型转换 | ❎类型错误，按原类型使用会crash |

测试结果可见，**YYModel和JSONModel在安全方面做的比较好**。

针对性能进行了测试，[测试用例为github的用户模型](https://github.com/ibireme/YYModel/blob/master/Benchmark/ModelBenchmark/GithubUserModel/GitHubUser.h)，该模型大部分属性是字符串，含有少量其他类型，是业务场景很常见的用例：

| 用例(10000 times) | 手动编码 | YYModel | JSONModel | Mantle  |
| ----------------- | -------- | ------- | --------- | ------- |
| 从JSON序列化      | 29.95    | 42.79   | 650.42    | 2341.57 |
| 序列化到JSON      | 27.47    | 90.53   | 368.90    | 1709.70 |

测试结果可见，**YYModel在性能方面做得最好，最接近手动编码，且甩开其他方案几个数量级**。

针对侵入性方面，YYModel做的也比较好，无需模型继承特殊类型，JSONModel和Mantle都需要继承特殊类型。**综上，移动网关选择了YYModel，并在YYModel基础上维护了BDModel**。



## 更新记录

- v0.0.1 初始版本，并解决编译器警告

- v0.0.2 添加snake格式和camel格式的JSON字段转换支持

  

## Author

mayufeng@bytedance.com

## License

BDModel is available under the MIT license. See the LICENSE file for more info.
