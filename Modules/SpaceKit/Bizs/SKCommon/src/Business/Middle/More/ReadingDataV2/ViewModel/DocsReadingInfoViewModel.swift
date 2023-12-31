//
//  DocsReadingInfoViewModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/18.
//  


import Foundation
import RxSwift
import RxCocoa
import UIKit
import UniverseDesignIcon
import SKResource
import UniverseDesignColor
import SKFoundation
import SpaceInterface


public final class DocsReadingInfoViewModel {
    
    public enum ReloadType {
        case onlyWords
        case onlyDetails
        case all
    }
    
    enum Status {
        case loading
        case fetchFail
        case needReload
        case none
    }
    
    struct Input {
        var trigger: BehaviorRelay<DocsReadingData?>
        var event: PublishRelay<DocDetailInfoViewController.Event>
    }

    struct Output {
        var data: PublishRelay<[DocDetainInfoSectionType]>
        var reload: PublishRelay<ReloadType>
        var status: BehaviorRelay<Status>
    }
    
    private var docsInfo: DocsInfo
    
    private(set) var data: [DocDetainInfoSectionType] = []
    
    private var disposeBag = DisposeBag()
    
    private var model: DocsReadingInfoModel?
    
    private var readingInfo: ReadingInfo?
    
    private var output: Output?

    var hasReceiveWords = false
    var hasReceiveDetails = false
    var permission: UserPermissionAbility?
    private let permissionService: UserPermissionService?

    private lazy var charCountNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ","
        return formatter
    }()
    
    public init(docsInfo: DocsInfo, permission: UserPermissionAbility?, permissionService: UserPermissionService?) {
        self.docsInfo = docsInfo
        self.permission = permission
        self.permissionService = permissionService
    }
}

extension DocsReadingInfoViewModel {
    /// 文档所有者的userId
    var docOwnerUserId: String? {
        return model?.user?.id
    }
    
    /// 文档所有者的头像
    var docOwnerAvatarUrl: String? {
        return model?.user?.avatarUrl
    }
}

extension DocsReadingInfoViewModel {
    
    func transform(input: Input) -> Output {
        let dataRelay = PublishRelay<[DocDetainInfoSectionType]>()
        input.trigger
             .subscribe(onNext: { [weak self] (data) in
                 guard let self = self, let info = data else { return }
                 switch info {
                 case .details(let model):
                     if model != nil {
                         self.model = model
                     }
                     self.hasReceiveDetails = true
                 case .words(let model), .fileMeta(let model):
                     if model != nil {
                         self.readingInfo = model
                     }
                     self.hasReceiveWords = true
                 }
                 self.constructData()
                 dataRelay.accept(self.data)
                 self.checkStatus()
            }).disposed(by: disposeBag)
        
        input.event
             .observeOn(MainScheduler.instance)
             .subscribe(onNext: { [weak self] (event) in
                 self?.handleEvent(event)
           }).disposed(by: disposeBag)
        
        output = Output(data: dataRelay,
                        reload: PublishRelay<DocsReadingInfoViewModel.ReloadType>(),
                        status: BehaviorRelay<Status>(value: .loading))
        return output!
    }
    
    func handleEvent(_ event: DocDetailInfoViewController.Event) {
        switch event {
        case .refresh:
            output?.status.accept(.loading)
            if model == nil {
                output?.reload.accept(.onlyDetails)
                return
            }
            if readingInfo == nil {
                output?.reload.accept(.onlyWords)
                return
            }
        case .retry:
            output?.status.accept(.loading)
            hasReceiveWords = false
            hasReceiveDetails = false
            output?.reload.accept(.all)
        }
    }
    
    func checkStatus() {
        DocsLogger.info("hasReceiveWords:\(hasReceiveWords) hasReceiveDetails:\(hasReceiveDetails)", component: LogComponents.docsDetailInfo)
        if hasReceiveWords,
           hasReceiveDetails {
            if readingInfo == nil, model == nil {
                output?.status.accept(.fetchFail)
                hasReceiveWords = false
                hasReceiveDetails = false
                DocsLogger.info("all fetch fail", component: LogComponents.docsDetailInfo)
            } else if readingInfo == nil {
                output?.status.accept(.needReload)
                DocsLogger.info("fetch readingInfo fail", component: LogComponents.docsDetailInfo)
            } else if model == nil {
                output?.status.accept(.needReload)
                DocsLogger.info("fetch model fail", component: LogComponents.docsDetailInfo)
            } else {
                output?.status.accept(.none)
            }
        }
    }
    
}

// MARK: - construct data
extension DocsReadingInfoViewModel {
    
    var contentHeight: CGFloat {
        if data.isEmpty {
           constructData()
        }
        return data.reduce(0) { $0 + $1.height } + 50
    }
    
    private func constructData() {
        var array: [DocDetainInfoSectionType] = []

        let rowTexts0: [(String, String)] = [
            (BundleI18n.SKResource.Doc_More_DocumentOwner, model?.user?.displayName ?? "N/A"),
            (BundleI18n.SKResource.Doc_More_CreationTime, self.model?.createTimestamp.creationTime ?? "N/A")
        ]
        array.append(.createInfo(DocsDetailInfoBaseInfo(title: BundleI18n.SKResource.CreationMobile_Stats_Basic_tab,
                                                        rowTexts: rowTexts0)))
        DocsLogger.info("show docs deading user name isEmpty: \(self.model?.user?.name.trim().isEmpty ?? false)", component: LogComponents.docsDetailInfo)
        
        if let fileInfo = constructFileInfo() {
            array.append(fileInfo)
        }
        
        var wordCount = "N/A"
        var characterCount = "N/A"
        if let readingInfo = readingInfo {
            for readInfo in readingInfo {
                if readInfo.type == .wordNumber {
                    if let intValue = Int(readInfo.detail) {
                        wordCount = charCountNumberFormatter.string(from: NSNumber(value: intValue)) ?? wordCount
                    } else {
                        wordCount = readInfo.detail
                    }
                }
                if readInfo.type == .charNumber {
                    if let intValue = Int(readInfo.detail) {
                        characterCount = charCountNumberFormatter.string(from: NSNumber(value: intValue)) ?? characterCount
                    } else {
                        characterCount = readInfo.detail
                    }
                }
            }
        }
        
        let wordCountSupportType: [DocsType] = DocDetailInfoViewController.supportWordCountTypes // 支持`字数统计`
        let charCountSupportType: [DocsType] = DocDetailInfoViewController.supportCharCountTypes // 支持`字符数统计`
        let supportWordCount = wordCountSupportType.contains(docsInfo.type)
        let supportCharCount = charCountSupportType.contains(docsInfo.type)
        let rowTexts: [(String, String)]
        if supportWordCount, supportCharCount {
            rowTexts = [
                (BundleI18n.SKResource.Doc_Doc_WordsCount, wordCount),
                (BundleI18n.SKResource.Doc_Doc_CharacterCount, characterCount)
            ]
        } else if supportWordCount, supportCharCount == false {
            rowTexts = [(BundleI18n.SKResource.Doc_Doc_WordsCount, wordCount)]
        } else if supportWordCount == false, supportCharCount {
            rowTexts = [(BundleI18n.SKResource.Doc_Doc_CharacterCount, characterCount)]
        } else {
            rowTexts = []
        }
        if rowTexts.isEmpty == false {
            array.append(.wordInfo(DocsDetailInfoBaseInfo(title: BundleI18n.SKResource.CreationMobile_Stats_Basic_words,
                                                          rowTexts: rowTexts)))
        }
        
        let firstBlock = DocsDetailInfoCountModel(title: BundleI18n.SKResource.Doc_Doc_ReaderCount,
                                                  countText: formatNumber(model?.uv),
                                                  newsCountText: formatIncrease(model?.uvToday))
        let secondBlock = DocsDetailInfoCountModel(title: BundleI18n.SKResource.Doc_Doc_ReadingCount,
                                                   countText: formatNumber(self.model?.pv),
                                                   newsCountText: formatIncrease(model?.pvToday))
        let thirdBlock = DocsDetailInfoCountModel(title: BundleI18n.SKResource.CreationMobile_Stats_Basic_comments,
                                                  countText: formatNumber(self.model?.commentsCount),
                                                  newsCountText: formatIncrease(model?.commentsCountToday))
        var readInfoBlocks = [firstBlock, secondBlock, thirdBlock]
        let thumbUpCountSupportType: [DocsType] = [.doc, .docX, .file]
        if thumbUpCountSupportType.contains(docsInfo.type) {
            let fourthBlock = DocsDetailInfoCountModel(title: BundleI18n.SKResource.Doc_Doc_ThumbUpCount,
                                                       countText: formatNumber(self.model?.likeCount),
                                                       newsCountText: formatIncrease(model?.likeCountToday))
            readInfoBlocks.append(fourthBlock)
        }
        array.append(.readInfo(blocks: readInfoBlocks))
        var showRecordInfoEntrance = false
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation, let permissionService {
            showRecordInfoEntrance = permissionService.validate(operation: .isFullAccess).allow
        } else if let permission {
            showRecordInfoEntrance = permission.canSinglePageManageMeta() || permission.canManageMeta()
        } else {
            // permission可能时机原因获取不到，兜底要owner才能看到入口
            showRecordInfoEntrance = docsInfo.isOwner
            DocsLogger.warning("permission is nil, fall back to owner", component: LogComponents.docsDetailInfo)
        }
        if showRecordInfoEntrance {
            array.append(.readRecordInfo(icon: UDIcon.visibleOutlined))
        }
        if docsInfo.isFromWiki || docsInfo.isSingleContainerNode {
            array.append(.documentActivity(icon: UDIcon.operationrecordOutlined))
        }
        array.append(.privacySetting(icon: UDIcon.settingOutlined))
        self.data = array
    }
    
    private func constructFileInfo() -> DocDetainInfoSectionType? {
        guard docsInfo.type == .file else {
            return nil
        }
        var fileType = "N/A"
        var fileSize = "N/A"
        for readInfo in (readingInfo ?? []) {
            if readInfo.type == .fileType {
                fileType = readInfo.detail
            }
            if readInfo.type == .fileSize {
                fileSize = readInfo.detail
            }
        }
        let rowTexts: [(String, String)] = [(BundleI18n.SKResource.Drive_Drive_FileType, fileType),
                                            (BundleI18n.SKResource.Drive_Drive_FileSize, fileSize)]
        return .fileInfo(DocsDetailInfoBaseInfo(title: BundleI18n.SKResource.Drive_Drive_FileGeneral,
                                                rowTexts: rowTexts))
    }
    
    func formatNumber(_ number: Int?) -> String {
        guard let value = number, value >= 0 else { return "N/A" }
        guard value >= 1000 else { return "\(value)" }
        let thousand = value / 1000
        let million = value / 1000000
        if million > 0 {
            return "\(million)" + BundleI18n.SKResource.CreationMobile_Common_Units_million
        } else {
            return ("\(thousand)") + BundleI18n.SKResource.CreationMobile_Common_Units_thousand
        }
    }
    
    private func formatIncrease(_ number: Int?) -> NSAttributedString? {
        guard let value = number, value > 0 else { return nil }
        let font = UIFont.systemFont(ofSize: 10)
        let formatValue = formatNumber(value)
        let text = BundleI18n.SKResource.CreationMobile_Stats_Basic_DailyNew(formatValue)
        let attachment = NSTextAttachment().construct { ct in
            ct.image = UDIcon.insertUpOutlined.ud.withTintColor(UDColor.functionSuccess700)
            ct.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
        }
        let attachmenString = NSMutableAttributedString(attachment: attachment)
        attachmenString.append(NSAttributedString(string: text))
        return attachmenString
    }
}
