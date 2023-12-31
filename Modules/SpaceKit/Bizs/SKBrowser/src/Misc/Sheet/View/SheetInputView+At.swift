//
//  SheetInputView+At.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/2/21.
//

import Foundation
import UIKit
import SKCommon
import SKFoundation
import SpaceInterface

extension SheetInputView {
    private func convertFromResponseToMentionSegment(from response: [String: Any]?, attributes: [NSAttributedString.Key: Any]?, atInfo: AtInfo) -> SheetMentionSegment {
        let mentionSegment = SheetMentionSegment()
        mentionSegment.type = .mention
        if let dict = response {
            let data = dict["data"] as? [String: Any] ?? [String: Any]()
            let resultList = data["result_list"] as? [[String: Any]] ?? [[String: Any]]()
            let realDict = resultList[0]
            
            mentionSegment.name = realDict["cn_name"] as? String ?? ""
            mentionSegment.enName = realDict["en_name"] as? String ?? ""
            mentionSegment.link = realDict["url"] as? String ?? ""
            mentionSegment.category = realDict["type"] as? Int == 0 ? "at-user-block" : "undefined"   //如果@文档是undefined?
            if realDict["type"] as? Int == 0 {
                mentionSegment.text = "@"
                mentionSegment.text.append(realDict["cn_name"] as? String ?? "")
            } else {
                mentionSegment.text = atInfo.at
            }
            //realDict 中的 id 是 userID，不是前端理解的 mentionID，这里传空给前端就行
            mentionSegment.mentionId = nil
            mentionSegment.token = realDict["token"] as? String ?? ""
            mentionSegment.mentionType = realDict["type"] as? Int ?? 0
            let icon = SuiteIcon()
            icon.key = realDict["icon_key"] as? String ?? ""
            icon.type = realDict["icon_type"] as? SuiteIconType ?? .unset
            icon.fsUnit = realDict["icon_fsunit"] as? String ?? ""
            mentionSegment.icon = icon
            if UserScopeNoChangeFG.HZK.sheetCustomIconPart {
                mentionSegment.iconInfo = realDict["icon_info"] as? String
            }
            mentionSegment.notNotify = realDict["not_notify"] as? Bool
            mentionSegment.style = convertFromAttributesToStyle(from: attributes ?? SheetFieldDataConvert.convertFromStyleToAttributes(from: cellStyle ?? SheetStyleJSON(), isSpecial: false))
            //response里面没有mentionNotify和blockNotify
            mentionSegment.mentionNotify = nil
            mentionSegment.blockNotify = nil
        }
        
        return mentionSegment
    }
    // MARK: AtListView
    func makeAtView() -> AtListView? {
        let at = self.delegate?.atViewController(type: .comment)
        at?.selectAction = { [weak self] (atInfo, response, index) in
            guard let atInfo = atInfo, let context = self?.atContext else { return }
            //sheet输入框暂时不显示自定义icon
            if !UserScopeNoChangeFG.HZK.sheetCustomIconPart {
                //fg没有开启，去掉自定义icon信息
                atInfo.iconInfoMeta = nil
            }
            var keyword = context.str
            if context.str.count == 0 {
                keyword = "@"
            }
            var attributes = self?.cellAttributes ?? SheetFieldDataConvert.convertFromStyleToAttributes(from: SheetStyleJSON(), isSpecial: false)
            if let len = self?.inputTextView.attributedText.length, len > 1, context.location > 1 {
                attributes = self?.inputTextView.attributedText.attributes(at: context.location - 2, effectiveRange: nil) ?? [NSAttributedString.Key: Any]()    //应该跟随前面的属性
            }
            let mentionSegment = self?.convertFromResponseToMentionSegment(from: response, attributes: attributes, atInfo: atInfo)  //将属性转换回style之前不应设置颜色 否则后续颜色跟随错误
            attributes.updateValue(UIColor.ud.colorfulBlue, forKey: .foregroundColor)   //设置颜色
            let keyAtt = NSMutableAttributedString(string: keyword, attributes: attributes)
            keyAtt.addAttribute(SheetInputView.attributedStringSegmentKey, value: mentionSegment as Any, range: NSRange(location: 0, length: keyAtt.length))   //为了后续转换方便 添加的@要先生成一个mentionSeg作为约束加上
            keyAtt.addAttribute(SheetInputView.attributedStringSpecialKey, value: "special", range: NSRange(location: 0, length: keyAtt.length))
            if let len = self?.inputTextView.attributedText.length, len > 1 {
                keyAtt.addAttribute(.paragraphStyle, value: NSParagraphStyle(), range: NSRange(location: 0, length: keyAtt.length))
            }
            let location = self?.inputTextView.selectedRange.location ?? 0
            self?.replaceStringToAttachment(keyAtt, with: atInfo, range: NSRange(location: location - keyAtt.length, length: keyAtt.length))
            self?.doStatisticsForAtConfirm(atInfo, in: index)
        }
        at?.invalidLayoutAction = { [weak self] in
            guard let `self` = self else { return }
            self.updateConstraintFor(self.mode)
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100, execute: {
                self.inputTextView.scrollRangeToVisible(self.inputTextView.selectedRange)
            })
        }
        at?.refresh(with: "", filter: self.atViewFilter())
        at?.cancelAction = { [weak self] in
            self?.hideAtView()
        }
        return at
    }

    func replaceStringToAttachment(_ replacement: NSAttributedString, with atInfo: AtInfo, range replacementRange: NSRange) {
        // 1. 获取 At Attributes String
        let atAttrString = atInfo.attributedString(attributes: replacement.attributes(at: 0, effectiveRange: nil), lineBreakMode: .byWordWrapping)  //字体相关属性保存
        
        atInfo.iconInfo?.image.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            let range = NSRange(location: 0, length: self.inputTextView.attributedText.length)
            self.inputTextView.layoutManager.invalidateDisplay(forCharacterRange: range)
        }).disposed(by: disposeBag)

        // 2. 获取原文
        let textAttrString = NSMutableAttributedString(attributedString: inputTextView.attributedText)

        // 3. 替换 keyword
        guard
            replacementRange.location >= 0,
            replacementRange.location < textAttrString.length,
            replacementRange.location + replacementRange.length <= textAttrString.length
        else {
            DocsLogger.info("at 数组越界 - \(textAttrString) -\(replacementRange)")
            return
        }
        textAttrString.replaceCharacters(in: replacementRange, with: atAttrString)

        hideAtView()
        atContext = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100, execute: { [weak self] in
            /// 等待其他 view 布局完成后，再更改 text。
            /// 不然会导致整个 textView 布局已经换了，里面的 contentView 还没重新布局
            guard let inputTextView = self?.inputTextView else { return }
            let newAttributes = self?.cellAttributes ?? inputTextView.typingAttributes
            textAttrString.append(NSAttributedString(string: " ", attributes: newAttributes))
            inputTextView.attributedText = textAttrString
            inputTextView.selectedRange = NSRange(location: replacementRange.location + atAttrString.length, length: 0)
            self?.callJSForTextChanged(text: textAttrString, editState: .editing)
            inputTextView.scrollRangeToVisible(inputTextView.selectedRange)
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100, execute: { [weak self] in
                self?.modifyNonFullModeIfNeed()
                self?.inputTextView.scrollRangeToVisible(inputTextView.selectedRange)
                self?.inputTextView.layoutIfNeeded()
                self?.superview?.layoutIfNeeded()
            })
        })
    }

    func showAtView(from atSource: AtSource = .button) {
        guard let at = currentAtListView() else {
            DocsLogger.info("无法生成 at list view")
            return
        }

        at.refresh(with: "", filter: atViewFilter())
        let height = currentAtListHeight()
        if !subviews.contains(at) {
            addSubview(at)
            if mode == .basic || mode == .multi {
                sendSubviewToBack(at)
                contentShowTopShadow(show: true)
                at.snp.remakeConstraints { (make) in
                    make.height.equalTo(height)
                    make.bottom.equalTo(contentView.snp.top)
                    make.width.equalToSuperview()
                }
            } else {
                bringSubviewToFront(at)
                at.snp.remakeConstraints { (make) in
                    make.height.equalTo(height)
                    make.bottom.equalToSuperview()
                    make.width.equalToSuperview()
                }
                self.enterFullAtMode()
            }
            self.atSource = atSource
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100, execute: {
                self.inputTextView.scrollRangeToVisible(self.inputTextView.selectedRange)
            })
            reportOpenAt(from: atSource)
        }
    }

    func relayoutAtView() {
        if let at = currentAtListView(), subviews.contains(at) {
            let height = currentAtListHeight()
            switch self.mode {
            case .basic, .multi:
                at.snp.remakeConstraints({ (make) in
                    make.height.equalTo(height)
                    make.bottom.equalTo(contentView.snp.top)
                    make.width.equalToSuperview()
                })
            case .full:
                at.snp.remakeConstraints({ (make) in
                    make.height.equalTo(height)
                    make.bottom.equalToSuperview()
                    make.width.equalToSuperview()
                })
            }
            at.refreshCurrentCollectionViewLayout()
        }
        self.layoutIfNeeded()
    }

    public func hideAtView() {
        self.contentShowTopShadow(show: false)
        if let at = currentAtListView(), subviews.contains(at) {
            at.removeFromSuperview()
            self.exitFullAtMode()
        }
    }
    func refreshAtView(with key: String?) {
        guard let str = key else { return }
        currentAtListView()?.refresh(with: str, filter: atViewFilter())
    }

    func updateAtContextIfNeed() {
        self.atContext?.str = _fetchKeyword(inputTextView.text, selectRange: inputTextView.selectedRange)
    }

    private func _fetchKeyword(_ text: String, selectRange: NSRange) -> String {
        let index = AtInfo.removeEmojiLocation(with: inputTextView, location: selectRange.location)
        let textBeforeSelectLocation = text.mySubString(to: index)
        if let lastAtIndex = textBeforeSelectLocation.lastIndex(of: "@") {
            let keyword = String(textBeforeSelectLocation[lastAtIndex...])
            if keyword.last == " " || keyword.last == "\n" {
                return ""
            } else {
                return keyword
            }
        } else { // 找不到 @
            return ""
        }
    }

    private func atViewFilter() -> Set<AtDataSource.RequestType> {
        return AtDataSource.RequestType.atViewFilter
    }
}

/// Statistics
extension SheetInputView {
    enum AtSource: String {
        /// 用户自己输入了 @
        case input = "keyboard"
        /// 通过按钮唤醒 @
        case button = "toolbar"
    }
    private func reportOpenAt(from atSource: AtSource) {
        guard let fileId = delegate?.fileIdForStatistics() else {
            spaceAssertionFailure()
            return
        }
        let zone = zoneForStatistics()
        let source = sourceForStatistics(atSource: atSource)
        let context = AtTracker.Context(module: DocsType.sheet, fileType: DocsType.sheet, fileId: fileId, zone: zone, source: source)
        AtTracker.logOpen(with: context)
        SheetTracker.report(event: .insertMention, docsInfo: self.docsInfo)
    }
    private func doStatisticsForAtConfirm(_ atInfo: AtInfo, in index: Int) {
        guard let fileId = delegate?.fileIdForStatistics() else {
            spaceAssertionFailure()
            return
        }
        let zone = zoneForStatistics()
        let source = sourceForStatistics(atSource: atSource)
        let mentionType = atInfo.type.strForMentionType
        let subType = atInfo.type.strForMentionSubType
        let context = AtTracker.Context(mentionType: mentionType,
                                        mentionSubType: subType,
                                        module: DocsType.sheet,
                                        fileType: DocsType.sheet,
                                        fileId: fileId,
                                        zone: zone,
                                        source: source)
        AtTracker.logConfirm(with: context)
    }
    private func zoneForStatistics() -> AtTracker.Zone {
        switch mode {
        case .basic, .multi:
            return .fxBar
        case .full:
            return .fullToolbar
        }
    }
    private func sourceForStatistics(atSource: AtSource?) -> AtTracker.Source {
        return (atSource == .input) ? AtTracker.Source.keyboard : AtTracker.Source.toolbar
    }
}
