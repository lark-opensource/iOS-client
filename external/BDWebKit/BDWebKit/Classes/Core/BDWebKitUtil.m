//
//  BDWebKitUtil.m
//  BDWebKit
//
//  Created by wealong on 2020/3/3.
//

#import "BDWebKitUtil.h"

@implementation BDWebKitUtil

+ (NSString *)contentTypeOfExtension:(NSString *)extension {
    static NSDictionary *g_ext2contentMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_ext2contentMap = @{
                             @"html" : @"text/html",
                             @"htm" : @"text/html",
                             @"shtml" : @"text/html",
                             @"css" : @"text/css",
                             @"xml" : @"text/xml",
                             @"gif" : @"image/gif",
                             @"jpeg" : @"image/jpeg",
                             @"jpg" : @"image/jpeg",
                             @"js" : @"application/x-javascript",
                             @"atom" : @"application/atom+xml",
                             @"rss" : @"application/rss+xml",
                             @"mml" : @"text/mathml",
                             @"txt" : @"text/plain",
                             @"jad" : @"text/vnd.sun.j2me.app-descriptor",
                             @"wml" : @"text/vnd.wap.wml",
                             @"htc" : @"text/x-component",
                             @"png" : @"image/png",
                             @"tif" : @"image/tiff",
                             @"tiff" : @"image/tiff",
                             @"wbmp" : @"image/vnd.wap.wbmp",
                             @"ico" : @"image/x-icon",
                             @"jng" : @"image/x-jng",
                             @"bmp" : @"image/x-ms-bmp",
                             @"svg" : @"image/svg+xml",
                             @"webp" : @"image/webp",
                             @"jar" : @"application/java-archive",
                             @"war" : @"application/java-archive",
                             @"ear" : @"application/java-archive",
                             @"hqx" : @"application/mac-binhex40",
                             @"doc" : @"application/msword",
                             @"pdf" : @"application/pdf",
                             @"ps" : @"application/postscript",
                             @"eps" : @"application/postscript",
                             @"ai" : @"application/postscript",
                             @"rtf" : @"application/rtf",
                             @"xls" : @"application/vnd.ms-excel",
                             @"ppt" : @"application/vnd.ms-powerpoint",
                             @"wmlc" : @"application/vnd.wap.wmlc",
                             @"kml" : @"application/vnd.google-earth.kml+xml",
                             @"kmz" : @"application/vnd.google-earth.kmz",
                             @"7z" : @"application/x-7z-compressed",
                             @"cco" : @"application/x-cocoa",
                             @"jardiff" : @"application/x-java-archive-diff",
                             @"jnlp" : @"application/x-java-jnlp-file",
                             @"run" : @"application/x-makeself",
                             @"pl" : @"application/x-perl",
                             @"pm" : @"application/x-perl",
                             @"pdb" : @"application/x-pilot",
                             @"rar" : @"application/x-rar-compressed",
                             @"rpm" : @"application/x-redhat-package-manager",
                             @"sea" : @"application/x-sea",
                             @"swf" : @"application/x-shockwave-flash",
                             @"sit" : @"application/x-stuffit",
                             @"tcl" : @"application/x-tcl",
                             @"tk" : @"application/x-tcl",
                             @"der" : @"application/x-x509-ca-cert",
                             @"pem" : @"application/x-x509-ca-cert",
                             @"crt" : @"application/x-x509-ca-cert",
                             @"xpi" : @"application/x-xpinstall",
                             @"xhtml" : @"application/xhtml+xml",
                             @"zip" : @"application/zip",
                             @"bin" : @"application/octet-stream",
                             @"exe" : @"application/octet-stream",
                             @"dll" : @"application/octet-stream",
                             @"deb" : @"application/octet-stream",
                             @"dmg" : @"application/octet-stream",
                             @"eot" : @"application/octet-stream",
                             @"iso" : @"application/octet-stream",
                             @"img" : @"application/octet-stream",
                             @"msi" : @"application/octet-stream",
                             @"msp" : @"application/octet-stream",
                             @"msm" : @"application/octet-stream",
                             @"mid" : @"audio/midi",
                             @"midi" : @"audio/midi",
                             @"kar" : @"audio/midi",
                             @"mp3" : @"audio/mpeg",
                             @"ogg" : @"audio/ogg",
                             @"ra" : @"audio/x-realaudio",
                             @"3gpp" : @"video/3gpp",
                             @"3gp" : @"video/3gpp",
                             @"mpeg" : @"video/mpeg",
                             @"mpg" : @"video/mpeg",
                             @"mov" : @"video/quicktime",
                             @"flv" : @"video/x-flv",
                             @"mng" : @"video/x-mng",
                             @"asx" : @"video/x-ms-asf",
                             @"asf" : @"video/x-ms-asf",
                             @"wmv" : @"video/x-ms-wmv",
                             @"avi" : @"video/x-msvideo",
                             @"m4v" : @"video/mp4",
                             @"mp4" : @"video/mp4",
                             };
    });
    return g_ext2contentMap[extension];
}

// process range data for mp4
+ (NSData *)rangeDataForVideo:(NSData *)fileData withRequest:(NSURLRequest *)request withResponseHeaders:(nonnull NSMutableDictionary *)responseHeaders {
    if (fileData == nil || request == nil) {
        return nil;
    }
    
    if ([request.URL.pathExtension isEqualToString:@"mp4"]) {
        NSString *rangeField = request.allHTTPHeaderFields[@"Range"];
        NSInteger requestRangeStart = 0, requestRangeEnd = 0;
        if ([rangeField hasPrefix:@"bytes="]) {
            NSArray<NSString *> *arrStr = [rangeField componentsSeparatedByString:@"="];
            if (arrStr.count > 1) {
                NSArray<NSString *> *arrRangeStr = [arrStr[1] componentsSeparatedByString:@"-"];
                requestRangeStart = [arrRangeStr[0] integerValue];
                if (arrRangeStr.count > 1) {
                    requestRangeEnd = [arrRangeStr[1] integerValue];
                }
            }
        }
        
        responseHeaders[@"Accept-Ranges"] = @"bytes";
        responseHeaders[@"Content-Type"] = @"video/mp4";
        
        if (BDWK_isEmptyString(rangeField)) {
            responseHeaders[@"Content-Length"] = [NSString stringWithFormat:@"%lu", (unsigned long)fileData.length];
            return nil;
        }
        
        NSInteger requestRangeSize = 0;
        if (requestRangeEnd != 0 && requestRangeEnd > requestRangeStart) {
            requestRangeSize = requestRangeEnd - requestRangeStart + 1;
        } else {
            requestRangeSize = fileData.length;
        }
        
        NSInteger dataLength;
        if (requestRangeEnd > 0) {
            dataLength = requestRangeEnd - requestRangeStart + 1;
            responseHeaders[@"Content-Length"] = [NSString stringWithFormat:@"%ld", dataLength];
            responseHeaders[@"content-range"] = [NSString stringWithFormat:@"bytes %ld-%ld/%ld", requestRangeStart, requestRangeEnd, fileData.length];
        } else {
            dataLength = fileData.length - requestRangeStart;
            responseHeaders[@"Content-Length"] = [NSString stringWithFormat:@"%ld", dataLength];
            responseHeaders[@"content-range"] = [NSString stringWithFormat:@"bytes %ld-%ld/%ld", requestRangeStart, (fileData.length - 1), fileData.length];
        }
        
        NSUInteger responseDataStart = 0;
        if (requestRangeStart > 0 && requestRangeStart < fileData.length) {
            responseDataStart = requestRangeStart;
        }
        NSUInteger responseDataLength = fileData.length - responseDataStart;
        if (dataLength > 0 && ((responseDataStart + dataLength) < fileData.length)) {
            responseDataLength = dataLength;
        }
        return [fileData subdataWithRange:NSMakeRange(responseDataStart, responseDataLength)];
    }
    
    return nil;
}

+ (NSString *)prefixMatchesInString:(NSString *)string withPattern:(NSString *) pattern
{
    if ([string length] == 0 || [pattern length] == 0) {
        return nil;
    }

    static NSCache<NSString *, NSRegularExpression *> *regexCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexCache = [[NSCache alloc] init];
        regexCache.totalCostLimit = 128 * 1024;
    });

    NSRegularExpression *regex = [regexCache objectForKey:pattern];
    if (!regex) {
        NSError *error = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) {
            return nil;
        }
        [regexCache setObject:regex forKey:pattern cost:pattern.length];
    }
    
    NSRange matchingRange = NSMakeRange(0, string.length);
    NSUInteger locationOfQuestionMark = [string rangeOfString:@"?"].location;
    if (locationOfQuestionMark != NSNotFound) {
        matchingRange.length = locationOfQuestionMark;
    }

    NSRange range = [regex rangeOfFirstMatchInString:string options:NSMatchingAnchored range:matchingRange];
    if (range.location != NSNotFound) {
        return [string substringWithRange:range];
    }

    return nil;
}

@end

BOOL BDWK_isEmptyString(id param)
{
    if(!param) {
        return YES;
    }
    if ([param isKindOfClass:[NSString class]]) {
        NSString *str = param;
        return (str.length == 0);
    }
    NSCAssert(NO, @"BTD_isEmptyString: param %@ is not NSString", param);
    return YES;
}
