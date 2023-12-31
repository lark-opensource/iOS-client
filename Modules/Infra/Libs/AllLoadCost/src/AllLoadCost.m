//
//  AllLoadCost.m
//  AllLoadCost
//
//  Created by CL7R on 2020/7/14.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//
#import "AllLoadCost.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach-o/getsect.h>
#import <AllLoadCost/AllLoadCost-Swift.h>

//通过数据段获取的category数据，需要使用objc-runtime-new.h源码中的结构体才能解析
struct lark_method_t {
    SEL name;
    const char *types;
    IMP imp;
};

struct lark_method_list_t {
    uint32_t entsizeAndFlags;
    uint32_t count;
    struct lark_method_t first;
};

struct lark_category_t {
    const char *name;
    Class cls;
    struct lark_method_list_t *instanceMethods;
    struct lark_method_list_t *classMethods;
};
//定义一个IMP
typedef void (* _LARKIMP) (id, SEL, ...);

static BOOL isLogger = true;

static NSMutableDictionary<NSString *, NSNumber *> *costDic;

static double totalTime = 0;

@implementation AllLoadCost: NSObject

+ (void)load {
    NSLog(@"[+load start]");
    CFTimeInterval startTimeSelf = CFAbsoluteTimeGetCurrent();
    costDic = [NSMutableDictionary dictionary];
    //获取App加载dylib的数量
    uint32_t imageCount = _dyld_image_count();
    //获取项目名称
    NSString *projectName = ((NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleExecutableKey]);
    NSLog(@"[+load-image]%@-%d",projectName,imageCount);
    for (uint32_t imgIndex = 0; imgIndex < imageCount; imgIndex++) {
        //获取image，并匹配
        const char *path = _dyld_get_image_name(imgIndex);
        NSString *imgPath = [NSString stringWithUTF8String:path];
        NSString *dylib = [[imgPath componentsSeparatedByString:@"/"] lastObject];
        if ([dylib isEqualToString:projectName]) {
            const struct mach_header * mhdr= _dyld_get_image_header(imgIndex);
            [AllLoadCost queryCategoryList:mhdr];
            [AllLoadCost queryClassList:mhdr];
            break;
        }
    }
    CFTimeInterval endTimeSelf = CFAbsoluteTimeGetCurrent();
    CFTimeInterval cost = endTimeSelf - startTimeSelf;
    costDic[[NSString stringWithUTF8String:class_getName(self)]] = @(cost*1000);
    //5s后执行打印，确保logger正常
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AllLoadCost queryAllLoadCost];
    });
}
/// 获取category
/// @param mhdr mach-o的header
+ (void)queryCategoryList:(const struct mach_header *)mhdr {
    size_t categroyBytes = 0;
    Category *cates = (Category *)getDataSection(mhdr, "__objc_nlcatlist", &categroyBytes);
    for (uint32_t cateIndex = 0; cateIndex < categroyBytes/sizeof(Category); cateIndex++) {
        struct lark_category_t * category_t = (struct lark_category_t *)cates[cateIndex];
        struct lark_method_list_t *method_list_t = category_t->classMethods;
        struct lark_method_t *method_tList = &method_list_t->first;
        Class metaClass = object_getClass(category_t->cls);
        NSLog(@"[+loadWithClassName]%@",category_t->cls);
        UInt32 methodCount = method_list_t->count;
        for (int methodIndex = 0; methodIndex < methodCount; methodIndex ++) {
            struct lark_method_t method_t = method_tList[methodIndex];
            NSString *loadName = NSStringFromSelector(method_t.name);
            if ([loadName isEqualToString:@"load"]) {
                Method method = class_getClassMethod(metaClass, method_t.name);
                if (!method) {
                    NSLog(@"[+loadMethod-null]%@-%s-%@",metaClass,category_t->name,method);
                    break;
                }
                NSString *categoryName = [NSString stringWithCString:category_t->name encoding:NSUTF8StringEncoding];
                [AllLoadCost swizzeLoadMethodInClasss:metaClass withCategory:categoryName withMethod:method isCategory:YES];
                break;
            }
        }
    }
}
/// 获取class
/// @param mhdr mach-o的header
+ (void)queryClassList:(const struct mach_header *)mhdr {
    size_t classBytes = 0;
    Class *classes = (Class *)getDataSection(mhdr, "__objc_nlclslist", &classBytes);
    for (uint32_t classIndex = 0; classIndex < classBytes/sizeof(Class); classIndex++) {
        Class clas = classes[classIndex];
        unsigned int methodCount = 0;
        //获取类方法列表，如果有分类重名的，原类方法排在最后，所以需要反向遍历
        Method *methods = class_copyMethodList(object_getClass(clas), &methodCount);
        for (unsigned int methodIndex = methodCount-1; methodIndex >= 0; methodIndex--) {
            Method method = methods[methodIndex];
            NSString *methodName = NSStringFromSelector(method_getName(method));
            if ([methodName isEqualToString:@"load"]) {
                [AllLoadCost swizzeLoadMethodInClasss:clas withCategory:@"" withMethod:method isCategory:NO];
                break;
            }
        }
    }
}
/// 方法交换
/// @param class 类
/// @param categoryName 类别
/// @param method 方法
/// @param isCategory 是否是类别
+ (void)swizzeLoadMethodInClasss:(Class)class
                    withCategory:(NSString *)categoryName
                      withMethod:(Method)method
                      isCategory:(BOOL)isCategory{

    _LARKIMP originaLoadImp = (_LARKIMP)method_getImplementation(method);
    id newLoadBlock = ^(Class class ,SEL sel){
        NSString *funcName = @"";
        if (isCategory) {
            funcName = [NSString stringWithFormat:@"%@(%@)",[NSString stringWithUTF8String:class_getName(class)],categoryName];
        }
        else {
            funcName = [NSString stringWithUTF8String:class_getName(class)];
        }
        [AllLoadCostSwiftBridge signpostStartWithFuncName:funcName];
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        originaLoadImp(class,sel);
        CFTimeInterval endTime = CFAbsoluteTimeGetCurrent();
        [AllLoadCostSwiftBridge signpostEndWithFuncName:funcName];
        CFTimeInterval cost = endTime - startTime;
        costDic[funcName] = @(cost*1000);
        totalTime = totalTime + cost*1000;
    };
    IMP newLoadIMP = imp_implementationWithBlock(newLoadBlock);
    method_setImplementation(method, newLoadIMP);

}
/// 通过data段获取class和categroy
/// @param mhdr mach-od header
/// @param sectname data段的节
/// @param bytes 数量
static void* getDataSection(const struct mach_header *mhdr, const char *sectname, size_t *bytes) {
    void *data = getsectiondata((void *)mhdr, "__DATA", sectname, bytes);
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_CONST", sectname, bytes);
    }
    if (!data) {
        data = getsectiondata((void *)mhdr, "__DATA_DIRTY", sectname, bytes);
    }
    return data;
}
/// 写文件
+ (void)writingFile {
    NSString *tmpPath = NSTemporaryDirectory( );
    NSLog(@"[+load-temp path]%@", tmpPath);
    NSString *fileName = @"AllLoadCost.txt";
    NSString *logFilePath = [tmpPath stringByAppendingPathComponent:fileName];
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    [defaultManager removeItemAtPath:logFilePath error:nil];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
}
/// 关闭文件
+ (void)closeFile {
    fclose(stderr);
    fclose(stdout);
}
/// 查询+load耗时
+ (NSDictionary *)queryAllLoadCost {
    if (costDic.count == 0) {
        NSLog(@"+load is zero");
        return nil;
    }
    if (!isLogger) {
        [AllLoadCost writingFile];
    }
    NSArray *keyArr = [costDic keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        if ([obj1 floatValue] < [obj2 floatValue]) {
            return  NSOrderedDescending;
        }
        else if ([obj1 floatValue] > [obj2 floatValue]) {
            return  NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
    }];
    //NSArray *keyArr = [costDic keysSortedByValueUsingSelector:@selector(compare:)];
    NSString *strLoad = @"";
    for (NSString *str in keyArr) {
        if ([str isEqualToString:@"AllLoadCost"]) {
            strLoad = [NSString stringWithFormat:@"[+load tools %@] = %.2f ms",str,[costDic[str] doubleValue]];
            NSLog(@"%@",strLoad);

        }
        else if ([str isEqualToString:@"AllStaticInitializerCost"]) {
            strLoad = [NSString stringWithFormat:@"[+load tools %@] = %.2f ms",str,[costDic[str] doubleValue]];
            NSLog(@"%@",strLoad);
            totalTime = totalTime - [costDic[str] doubleValue];
        }
        else {
            strLoad = [NSString stringWithFormat:@"[+load][%@] = %.2f ms",str,[costDic[str] doubleValue]];
            NSLog(@"%@",strLoad);
        }
        [AllLoadCostSwiftBridge printLogWithInfo:strLoad];
    }
    NSString *strAll = [NSString stringWithFormat:@"[+load counts =%lu，all cost = %.2f ms",(costDic.count - 2),totalTime];
    [AllLoadCostSwiftBridge printLogWithInfo:strAll];
    NSLog(@"%@",strAll);
    if (!isLogger) {
        [AllLoadCost closeFile];
    }
    return costDic;
}

@end
