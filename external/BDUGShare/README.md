# BDUGShare

## Documents

Share产品文档：[Documents](https://doc.bytedance.net/docs/359/535/5017/)

iOS接入文档：[Documents](http://doc.bytedance.net/docs/359/536/4771/)

## Release Notes

1.3.0-rc.7:
```
1、拆除twitter和snapchat, 分别独立成BDUGShareTwitterBusiness和BDUGShareSnapChatBusiness。
2、增加微信小程序分享。
3、接入log系统，【需要业务方在podfile中引入BDUGLogger】。
4、删除BDUGShareImageURL分享方式，修改BDUGShareImage分享方式为以contentItem中的imageURL字段优先级 > image
5、删除BDUGShareUI/Panel中的所有icon资源，业务方可在demo中下载所需的icon放入自己的工程中。
icon下载地址：http://sf1-hscdn-tos.pstatp.com/obj/vcloud/a5ee7203da17c9dfb28f0e1d157d9598。
6、增加抖音透传参数，见：BDUGAwemeContentItem.awemeIdentifier。
7、BDUGShareUI/Token和BDUGShareUI/Video下的service增加初始化调用。（@required）。
```

1.2.0-rc.23 :
```
增加Facebook，Twitter等10来个海外渠道。
```

1.1.0: 
```
增加微博，抖音分享渠道，增加视频分享方式。
增加QQ、微信、钉钉、支付宝等分享渠道，增加图片隐写，文字口令等分享方式。
```

## Author

yangyang.melon@bytedance.com

## License

BDUGShare is available under the MIT license. See the LICENSE file for more info.
