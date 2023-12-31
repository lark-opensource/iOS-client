//
//  CCMWikiTreeSearchProxy.swift
//  CCMMod
//
//  Created by Weston Wu on 2023/6/5.
//

#if MessengerMod
import Foundation
import LarkSearchCore
import LarkModel
import SpaceInterface
import SKFoundation

class CCMPickerPlaceHolderTopView: UIView {
    let proxy: SearchPickerDelegate

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 0)
    }

    init(proxy: SearchPickerDelegate) {
        self.proxy = proxy
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CCMWikiTreeSearchProxy: SearchPickerDelegate {

    enum SearchType {
        case wikiNode
        case wikiSpace
    }

    weak var delegate: WikiTreeSearchDelegate?
    var searchType: SearchType

    init(delegate: WikiTreeSearchDelegate, type: SearchType = .wikiNode) {
        self.delegate = delegate
        self.searchType = type
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        guard let item = items.first else {
            DocsLogger.error("picker did finish without item")
            return false
        }
        switch searchType {
        case .wikiNode:
            guard case let .wiki(meta) = item.meta,
                  let wikiMeta = meta.meta else {
                DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
                return false
            }

            let objType = DocsType(pbDocsType: wikiMeta.type)
            let wikiNode = WikiNodeMeta(wikiToken: wikiMeta.token, objToken: wikiMeta.id, docsType: objType, spaceID: String(wikiMeta.spaceID))
            let result: WikiSearchResultItem = .wikiNode(node: wikiNode)
            delegate?.searchController(pickerVc, didClick: result)

        case .wikiSpace:
            guard case let .wikiSpace(meta) = item.meta,
                  let wikiSpaceMeta = meta.meta else {
                DocsLogger.error("un-expected item meta type found: \(item.meta.type)")
                return false
            }
            let result: WikiSearchResultItem = .wikiSpace(id: wikiSpaceMeta.spaceID,
                                                      name: wikiSpaceMeta.spaceName)
            delegate?.searchController(pickerVc, didClick: result)
        }

        return false
    }

    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        delegate?.searchControllerDidClickCancel(pickerVc)
        return false
    }
}

#endif
