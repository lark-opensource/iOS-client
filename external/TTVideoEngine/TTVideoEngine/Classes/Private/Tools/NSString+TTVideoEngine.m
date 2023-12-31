//
//  NSString+TTVideoEngine.m
//  TTVideoEngine
//
//  Created by 黄清 on 2018/11/13.
//

#import "NSString+TTVideoEngine.h"

@implementation NSString (TTVideoEngine)

- (NSString *)ttvideoengine_transformEncode {
    if (self.length == 0) {
        return self;
    }
    
    NSString* temString = [self stringByReplacingOccurrencesOfString:@"_" withString:@"$"];
    temString = [temString stringByReplacingOccurrencesOfString:@"/" withString:@"@"];
    temString = [temString stringByReplacingOccurrencesOfString:@"." withString:@"#"];
    return temString;
}

- (NSString *)ttvideoengine_transformDecode {
    if (self.length == 0) {
        return self;
    }
    
    NSString* temString = [self stringByReplacingOccurrencesOfString:@"$" withString:@"_"];
    temString = [temString stringByReplacingOccurrencesOfString:@"@" withString:@"/"];
    temString = [temString stringByReplacingOccurrencesOfString:@"#" withString:@"."];
    return temString;
}

- (CGSize)ttvideoengine_sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode {
    CGSize result;
    if (!font) font = [UIFont systemFontOfSize:12];
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableDictionary *attr = [NSMutableDictionary new];
        attr[NSFontAttributeName] = font;
        if (lineBreakMode != NSLineBreakByWordWrapping) {
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineBreakMode = lineBreakMode;
            attr[NSParagraphStyleAttributeName] = paragraphStyle;
        }
        CGRect rect = [self boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attr context:nil];
        result = rect.size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [self sizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    return result;
}

- (NSNumber*)ttvideoengine_stringToNSNumber{
    if (self.length <= 0) {
        return @(0);
    }
    NSArray *results = [self componentsSeparatedByString:@"."];
    if (results.count <= 0) {
        return @(0);
    }
    NSInteger versionCode;
    for (int i = 0; i < results.count; i++) {
        NSInteger result = 0;
        if (i == 0) {
            versionCode = [results[i] integerValue];
        }else {
            result = [results[i] integerValue];
            versionCode = versionCode*100 + result;
        }
    }
    return @(versionCode);
    
}

- (nullable NSDictionary *)ttvideoengine_jsonStr2Dict {
    NSError *error;
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
}

@end
