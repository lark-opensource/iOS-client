//
//  BDUGTokenShareAnalysisResultCommom.h
//  Article
//
//  Created by zengzhihui on 2018/6/1.
//

typedef NS_ENUM(NSInteger, BDUGTokenShareDialogType) {
    BDUGTokenShareDialogTypeText = 0,//口令解析纯文本类型
    BDUGTokenShareDialogTypeTextAndImage = 1,//口令解析图文类型
    BDUGTokenShareDialogTypePhotos = 2,//口令解析图集类型
    BDUGTokenShareDialogTypeVideo = 3,//口令解析视频类型
    BDUGTokenShareDialogTypeShortVideo = 4, //口令解析小视频类型
    BDUGTokenShareDialogTypeAudio = 5, //口令解析音频类型
};

@class BDUGTokenShareAnalysisResultModel;

typedef void(^BDUGTokenTapActionHandler)(BDUGTokenShareAnalysisResultModel *resultModel);
