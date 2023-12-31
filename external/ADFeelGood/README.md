
## ADFeelGood

1. ADFeelGood是一套支持在当前APP页面上弹出调查问卷的封装SDK，帮助APP收集用户问卷信息，为提升APP的使用体验提供方向
2. 搭配问卷配置后台使用
3. 接入咨询请先联系 @汤迅 @王瑞香 @李练仑 

## ADFeelGood的技术方案

1. 使用WKWebView展示问卷，使用level为alert+1的window承载
2. 通过配置的baseURL跳转，H5使用bridge收集客户端传递的参数，路由到指定的问卷
3. 通过bridge，H5可以主动关闭弹层

## ADFeelGood异常处理方案

1. 使用loading页面过度加载H5的等待时间，设置最长10s的超时时间
2. 设置EmptyView作为请求失败的兜底，支持点击关闭和刷新重试

## pod接入方式
pod_source 'ADFeelGood', 'x.x.x'

## 中台地址
http://mobile.bytedance.net/components/ADFeelGood?appId=999901&appType=1&repoId=10631&tabKey=readme

## ADFeelGood调用说明
1. 配置ADFeelGoodConfig，ps：如果用户更换等行为需要更新config

~~~
    ADFeelGoodConfig *config = [[ADFeelGoodConfig alloc] init];
    config.appKey = @"xxx";//feelgood后台生成的密钥
    config.channel = @"cn";//中国区为cn 非中国区为va
    config.language = @"zh_CN";//问卷语言 默认为zh_CN
    config.uid = @"user_id";//用户id
    config.uName = @"user_name";//用户昵称
    config.did = @"device_id";//设备id
    [[ADFeelGoodManager sharedInstance] setConfig:config];
~~~

2. 在触发场景检查获取对应的问卷

~~~
    __weak typeof(self) weakSelf = self;
    [[ADFeelGoodManager sharedInstance] checkQuestionnaireWithSceneID:场景id extraParams:nil completion:^(BOOL success, NSDictionary * _Nonnull data, NSError * _Nonnull error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //解析获取的数据 查看是否有场景匹配的taskid 
        NSArray *list = [[data objectForKey:@"data"] objectForKey:@"task_list"];
        if ([list isKindOfClass:[NSArray class]] && list.count > 0) {
            strongSelf.taskIDLabel.text = list[0];
        }else{
            //@"获取失败，或无可用taskid";
        }
    }];
~~~

3. 调起问卷弹窗

~~~
    [[ADFeelGoodManager sharedInstance] openQuestionnaireWithSceneID:场景id taskID:问卷taskid extraParams:nil pageDidOpenBlk:^{
        NSLog(@"打开了问卷弹窗");
    } pageDidCloseBlk:^(BOOL hadSubmit) {
        NSLog(@"关闭了问卷弹出 切用户是否提交成功 : %@",hadSubmit);
    }];
~~~


