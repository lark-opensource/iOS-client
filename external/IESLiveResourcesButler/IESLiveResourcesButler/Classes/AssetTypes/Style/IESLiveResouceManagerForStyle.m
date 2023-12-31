//
//  IESLiveResouceManagerForStyle.m
//  Pods
//
//  Created by Zeus on 17/1/6.
//
//

#import "IESLiveResouceManagerForStyle.h"
#import "IESLiveResouceStyleModel.h"

@interface IESLiveResouceManagerForStyle()

@property (nonatomic, strong) NSMutableDictionary *allStyles;
@property (nonatomic, strong) NSArray *tables;

@end

@implementation IESLiveResouceManagerForStyle

+ (void)load
{
    [IESLiveResouceManager registerAssetManagerClass:[self class] forType:@"style"];
}

- (instancetype)initWithAssetBundle:(IESLiveResouceBundle *)assetBundle type:(NSString *)type
{
    self = [super initWithAssetBundle:assetBundle type:type];
    if (self) {
        NSString *typePath = [assetBundle.bundle.bundlePath stringByAppendingPathComponent:type];
        NSArray *tableFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:typePath error:nil];
        NSMutableArray *tablesOfFullPath = [NSMutableArray array];
        for (NSString *tableFile in tableFiles) {
            [tablesOfFullPath addObject:[typePath stringByAppendingPathComponent:tableFile]];
            
        }
        self.tables = [tablesOfFullPath copy];
    }
    return self;
}

- (IESLiveResouceStyleModel *)objectForKey:(NSString *)key
{
    if (!self.allStyles) {
        self.allStyles = [NSMutableDictionary dictionary];
        for (NSString *table in self.tables) {
            NSString *content = [NSString stringWithContentsOfFile:table encoding:NSUTF8StringEncoding error:nil];
            [self.allStyles addEntriesFromDictionary:[self parseFromContent:content]];
        }
    }
    return [self.allStyles objectForKey:key];
}

- (NSDictionary *)parseFromContent:(NSString *)content
{
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    NSScanner *theScanner = [NSScanner scannerWithString:content];
    while (![theScanner isAtEnd]) {
        NSString *proStr;
        NSString *valueStr;
        if ([theScanner scanUpToString:@"{" intoString:&proStr] && [theScanner scanString:@"{"  intoString:NULL] && [theScanner scanUpToString:@"}" intoString:&valueStr] && [theScanner scanString:@"}" intoString:NULL] ) {
           proStr = [proStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            resultDic[proStr] = [self parseValueStr:valueStr];
        }
    }
    return resultDic;
}

- (IESLiveResouceStyleModel *)parseValueStr:(NSString *)string
{
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    NSScanner *theScanner = [NSScanner scannerWithString:string];
    while (![theScanner isAtEnd]) {
        NSString *proStr;
        NSString *valueStr;
        if ([theScanner scanUpToString:@":" intoString:&proStr] && [theScanner scanString:@":" intoString:NULL] && [theScanner scanUpToString:@";" intoString:&valueStr] && [theScanner scanString:@";" intoString:NULL]) {
            resultDic[proStr] = valueStr;
        }
    }
    
    IESLiveResouceStyleModel *style = [[IESLiveResouceStyleModel alloc] initWithDictionary: resultDic assetBundle:self.assetBundle];
    return style;
}

@end
