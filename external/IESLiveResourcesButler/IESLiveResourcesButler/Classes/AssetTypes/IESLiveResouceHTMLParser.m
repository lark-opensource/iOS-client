//
//  IESLiveResouceHTMLParser.m
//  Pods
//
//  Created by Zeus on 2016/12/27.
//
//

#import "IESLiveResouceHTMLParser.h"
#import <libxml/HTMLparser.h>
#import "NSString+IESLiveResouceBundle.h"

@interface IESLiveResouceHTMLParser () {
    htmlDocPtr _docPtr;
}
@end

@implementation IESLiveResouceHTMLParser

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static IESLiveResouceHTMLParser *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[IESLiveResouceHTMLParser alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _docPtr = NULL;
    }
    return self;
}

- (NSAttributedString *)parseHTMLWithString:(NSString *)string error:(NSError **)error{
    if ([string length] > 0) {
        CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
        CFStringRef cfencstr = CFStringConvertEncodingToIANACharSetName(cfenc);
        const char *enc = [(__bridge NSString*)cfencstr UTF8String];
        int optionsHtml = HTML_PARSE_RECOVER | HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING;
        _docPtr = htmlReadDoc ((xmlChar*)[string UTF8String], NULL, enc, optionsHtml);
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"IESLiveResouceHTMLParserdomain" code:1 userInfo:nil];
        }
        return nil;
    }
    return [self parseRoot:xmlDocGetRootElement(_docPtr) withAttribute:[NSMutableDictionary new]];
}

- (NSAttributedString *)parseRoot:(xmlNode *)root withAttribute:(NSMutableDictionary *)attribute {
    NSMutableAttributedString *ret = [NSMutableAttributedString new];
    if (root) {
        if (strcmp((char *)root->name, "text") == 0) {
            [ret appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:(char *)root->content] attributes:attribute]];
        } else {
            [self parseNode:root toAttribute:attribute];
        }
        for (xmlNode *child = root->children; child; child = child->next) {
            [ret appendAttributedString:[self parseRoot:child withAttribute:[attribute mutableCopy]]];
        }
    }
    return [ret copy];
}

- (void)parseNode:(xmlNode *)node toAttribute:(NSMutableDictionary *)attribute {
    if (strcmp((char *)node->name, "span") == 0) {
        for (xmlAttrPtr attr = node->properties; attr; attr = attr->next) {
            if (strcmp((char *)attr->name, "style") == 0) {
                [self parseSpanStyle:[NSString stringWithUTF8String:(char *)xmlNodeListGetString(node->doc, attr->children, 1)] toAttribute:attribute];
            }
        }
    } else if (strcmp((char *)node->name, "strike") == 0) {
        if ([[UIDevice currentDevice].systemVersion hasPrefix:@"10.3"]) { // https://stackoverflow.com/questions/43070335/
            attribute[NSBaselineOffsetAttributeName] = @(NSUnderlineStyleNone);
        }
        attribute[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
        for (xmlAttrPtr attr = node->properties; attr; attr = attr->next) {
            if (strcmp((char *)attr->name, "style") == 0) {
                [self parseStrikeStyle:[NSString stringWithUTF8String:(char *)xmlNodeListGetString(node->doc, attr->children, 1)] toAttribute:attribute];
            }
        }
    }
}

- (void)parseStrikeStyle:(NSString *)style toAttribute:(NSMutableDictionary *)attribute {
    [[style componentsSeparatedByString:@";"] enumerateObjectsUsingBlock:^(NSString * _Nonnull property, NSUInteger idx, BOOL * _Nonnull stop) {
        if (property.length > 0) {
            NSArray *kv = [property componentsSeparatedByString:@":"];
            if ([[kv firstObject] isEqualToString:@"color"]) {
                attribute[NSStrikethroughColorAttributeName] = [[kv lastObject] ies_lr_colorFromARGBHexString];
            }
        }
    }];
}

- (void)parseSpanStyle:(NSString *)style toAttribute:(NSMutableDictionary *)attribute {
    [[style componentsSeparatedByString:@";"] enumerateObjectsUsingBlock:^(NSString * _Nonnull property, NSUInteger idx, BOOL * _Nonnull stop) {
        if (property.length > 0) {
            NSArray *kv = [property componentsSeparatedByString:@":"];
            if ([[kv firstObject] isEqualToString:@"color"]) {
                attribute[NSForegroundColorAttributeName] = [[kv lastObject] ies_lr_colorFromARGBHexString];
            } else if ([[kv firstObject] isEqualToString:@"font-size"]) {
                attribute[NSFontAttributeName] = [UIFont systemFontOfSize:[[kv lastObject] floatValue]];
            } else if ([[kv firstObject] isEqualToString:@"background-color"]) {
                attribute[NSBackgroundColorAttributeName] = [[kv lastObject] ies_lr_colorFromARGBHexString];
            }
        }
    }];
}

@end
