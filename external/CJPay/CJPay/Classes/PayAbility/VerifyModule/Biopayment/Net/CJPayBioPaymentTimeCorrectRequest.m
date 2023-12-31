//
//  CJPayBioPaymentTimeCorrectRequest.m
//  CJPay
//
//  Created by 王新华 on 2019/1/22.
//

#import "CJPayBioPaymentTimeCorrectRequest.h"
#import "CJPayBioManager.h"
#import "CJPaySDKMacro.h"

double CJPayLocalTimeServerTimeDelta = 0;

@implementation CJPayBioPaymentTimeCorrectRequest

+ (void)checkServerTimeStamp {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithURL:[NSURL URLWithString:[self deskServerUrlString]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSString *serverTimeStamp = [httpResponse.allHeaderFields cj_stringValueForKey:@"Date"];
            
            CJPayLocalTimeServerTimeDelta = [[NSDate alloc] init].timeIntervalSince1970 - [self dateFromRFC822String:serverTimeStamp].timeIntervalSince1970;
        } else {
            CJPayLocalTimeServerTimeDelta = 0;
        }
    }];
    [task resume];
}

+ (NSString *)deskServerUrlString {
    return [NSString stringWithFormat:@"%@/%@", [self deskServerHostString], @"gateway-u"];
}

// Instantiate single date formatter
+ (NSDateFormatter *)internetDateTimeFormatter {
    static dispatch_once_t onceToken;
    
    static NSDateFormatter *_internetDateTimeFormatter;
    dispatch_once(&onceToken, ^{
        NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _internetDateTimeFormatter = [[NSDateFormatter alloc] init];
        [_internetDateTimeFormatter setLocale:en_US_POSIX];
        [_internetDateTimeFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    return _internetDateTimeFormatter;
}

// See http://www.faqs.org/rfcs/rfc822.html
+ (NSDate *)dateFromRFC822String:(NSString *)dstr {
    if(dstr == nil || dstr == NULL) {
        CJPayLogInfo(@"Something wrong with RFC822 date string: \"%@\". Check the format.", dstr);
        return nil;
    }
    NSDate *d_ret = nil;
    NSDateFormatter *dFor = [self internetDateTimeFormatter];
    @synchronized(dFor) {
        NSString *upperDstr = [[NSString stringWithString:dstr] uppercaseString];
        if(![upperDstr containsString:@","]) {
            
            /*  格式对应
                EEE, d  MMM  yyyy HH:mm:ss zzz
                 |   |   |    |   |  |  |   |
            Tuesday, 15 June 2021 17:05:12 GMT
             */
            
            [dFor setDateFormat:@"d MMM yyyy HH:mm"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"d MMM yyyy HH:mm:ss"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"d MMM yyyy HH:mm zzz"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"d MMM yyyy HH:mm:ss zzz"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
        } else {
            
            [dFor setDateFormat:@"EEE, d MMM yyyy HH:mm"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"EEE, d MMM yyyy HH:mm:ss"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
            [dFor setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"];
            d_ret = [dFor dateFromString:upperDstr];
            if(d_ret)return d_ret;
            
        }
    }
    if (d_ret==nil) CJPayLogInfo(@"Something wrong with RFC822 date string: \"%@\". Please check the format.", dstr);
    return d_ret;
}

@end
