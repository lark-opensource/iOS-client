//
//  OPNoticeModel.m
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

#import "OPNoticeModel.h"

@implementation OPNoticeUrlModel

- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
    
}

@end


@implementation OPNoticeModel

- (void)setValue:(id)value forKey:(NSString *)key{
    [super setValue:value forKey:key]; // 必须调用父类方法
    if ([key isEqualToString:@"link"]) { // 特殊字符处理
        OPNoticeUrlModel * urlModel = [[OPNoticeUrlModel alloc]init]; // 模型嵌套模型
        [urlModel setValuesForKeysWithDictionary:value];
        self.link = urlModel;
    }
}

// 防止意外崩溃
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{

}




@end
