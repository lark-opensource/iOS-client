//
//  DLPFeedbackComponentViewModel.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/18.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkCore
import LarkUIKit
import LarkMessengerInterface
import EEAtomic
import LarkAlertController
import LKCommonsLogging

public protocol DLPFeedbackComponentViewModelContext: ViewModelContext {}

class DLPFeedbackComponentViewModelLogger {
    static let logger = Logger.log(DLPFeedbackComponentViewModelLogger.self, category: "Module.Moments.DLPFeedbackComponentViewModelLogger ")
}
class DLPFeedbackComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DLPFeedbackComponentViewModelContext>: MessageSubViewModel<M, D, C> {

    static var logger: Log {
        return DLPFeedbackComponentViewModelLogger.logger
    }

    var icon: UIImage {
        return Resources.dlp_tip
    }

    var iconSize: CGSize {
        return .square(UIFont.ud.caption1.pointSize)
    }

    lazy var tipTextAttributes: [NSAttributedString.Key: Any] = {
        return [
            .font: UIFont.ud.caption1,
            .foregroundColor: UIColor.ud.functionDangerContentDefault
            ]
    }()

    lazy var feedBackTextAttributes: [NSAttributedString.Key: Any] = {
        return [
            .font: UIFont.ud.caption1,
            .foregroundColor: UIColor.ud.textLinkNormal
            ]
    }()

    func getAttrbuteTextInfo() -> (NSAttributedString, [LKTextLink]) {
        guard let securityExtra = message.securityExtra else {
            assertionFailure("may be somethings error")
            Self.logger.error("securityExtra isEmpty")
            return (NSAttributedString(string: ""), [])
        }
        Self.logger.info("getAttrbuteTextInfo \(securityExtra.submitText.count) \(securityExtra.tipText.count)")
        let range = (securityExtra.tipText as NSString).range(of: "{SubmitFeedback}")
        if range.length == 0 {
            Self.logger.error("\(self.metaModel.getChat().id) range isEmpty")
        }

        let attr = NSMutableAttributedString(string: securityExtra.tipText, attributes: tipTextAttributes)
        attr.replaceCharacters(in: range, with: securityExtra.submitText)
        let submitTextRange = NSRange(location: range.location, length: securityExtra.submitText.utf16.count)
        attr.addAttributes(feedBackTextAttributes, range: submitTextRange)
        var link = LKTextLink(range: submitTextRange,
                              type: .link,
                              attributes: feedBackTextAttributes)
        link.linkTapBlock = { [weak self] (_, _) in
            guard let url = URL(string: securityExtra.feedBackURL) else {
                Self.logger.error("linkTapBlock error --\(securityExtra.feedBackURL)")
                return
            }
            if let httpUrl = url.lf.toHttpUrl() {
                self?.context.navigator(type: .push, url: httpUrl, params: nil)
            } else {
                self?.context.navigator(type: .push, url: url, params: nil)
            }
        }
        let linkList = [link]
        return (attr, linkList)
    }
}
