//
//  LVDraftMigrationDefinition.h
//  Pods
//
//  Created by kevin gao on 9/24/19.
//

#ifndef LVDraftMigrationDefinition_h
#define LVDraftMigrationDefinition_h

/*
 错误码
 */
typedef enum : NSInteger {
    noError = 0,        //没有错误发生
    copyPathFail = 1,   //文件拷贝失败
    jsonNotExist = 2,   //找不到json文件
    decodeFail = 3,     //json decode失败
    parseFailed = 4,
    segmentIDNotExisted = 5,
    draftIDNotExisted = 6,
    materialIDNotExisted = 7,
    effectIDNotExisted = 8,
    emptyTrack = 9,
    durationIsZero = 10,
    handleFileFailed = 11,
    migrateFail = 12,           //某个迁移任务失败，流程abort
    videoSizeInvalid = 13,
    payloadIDNotExisted = 14,
    stickerIDNotExisted = 15,
    animationTypeNotExisted = 16,
    notNeedUpdate = 17,
    writeBackJsonFail = 18,     //json处理完毕回写失败
    trackTypeEmpty = 19,
    missingDraftID = 20,
    resourceNotExist = 21,
    userCancel = 22,
    downloadEffectFailed = 23,        // 下载效果包失败
    downloadEffectListFailed = 24,    // 下载效果列表失败
    effectDontMatch = 25,             // 存在草稿未能匹配正确的效果包
    homeDirectionError = 26,          // 沙盒主路径获取不到，一般不会有
    fontNotExit = 27,                 // 字体不存在
    fontCopyFail = 28,                // 字体文件拷贝失败
    haveNoAnyVideoMaterial = 29,      // 没有任何视频素材
    copyToTempFailed = 30,            // 拷贝草稿到临时目录错误
    copyToDstFailed = 31,             // 拷贝草稿到目标目录错误
    taskCountOutOfBoundOfArray = 32,  // Migration任务数超出配置数目
    generateImageFailed  = 33,        // 生成素材图片失败
    gameplayGetReshapeFailed = 34     // 获取玩法是否形变失败
} LVMigrationResultError;

/*
 流程状态
 */
typedef enum : NSUInteger {
    begin,          //开始迁移
    copyDirectory,  //拷贝目录
    loadJson,       //加载json
    migrationing,   //迁移中
    complete,       //迁移完成
    fail            //迁移失败
} LVMigrationProcess;


/*
版本号转换NSInteger
*/
static NSInteger genVersionForInteger(NSString* versionString) {
    NSArray* subStrings = [versionString componentsSeparatedByString:@"."];
    if (subStrings.count != 3) {
        return 0;
    }
    NSInteger version = 0;
    NSInteger index = 0;
    NSString* currentString = @"";
    NSEnumerator *enumerator = subStrings.reverseObjectEnumerator;
    while (currentString = [enumerator nextObject]) {
        NSInteger value = currentString.integerValue;
        NSInteger weight = powf(10.0, (float)index*2.0);
        version += value*weight;
        index ++;
    }
    return version;
}


#endif /* LVDraftMigrationDefinition_h */
