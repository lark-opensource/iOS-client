//
//  ACCPersonalRecommendWords.h
//  Indexer
//
//  Created by raomengyun on 2021/11/29.
//

#import <Foundation/Foundation.h>

// 个性化推荐文案
@interface ACCPersonalRecommendWords : NSObject

// 根据配置的 key 获取文案
+ (NSString *)wordsWithKey:(NSString *)key;

@end

// 获取文案
static inline NSString *ACCPersonalRecommendGetWords(NSString *key)
{
    return [ACCPersonalRecommendWords wordsWithKey:key];
}
