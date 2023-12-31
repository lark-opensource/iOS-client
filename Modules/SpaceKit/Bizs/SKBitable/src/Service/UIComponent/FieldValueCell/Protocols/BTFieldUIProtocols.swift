//
//  BTFieldUIProtocols.swift
//  SKBitable
//
//  Created by zhysan on 2023/7/10.
//

import Foundation
import SKBrowser

enum BorderMode {
    case normal
    case editing
    case error
    case none       // 隐藏边框，同时隐藏 errorMsgLabel
    case noBorder   // 仅仅隐藏边框，但不隐藏 errorMsgLabel
}

protocol BTFieldModelLoadable: UICollectionViewCell {

    var fieldModel: BTFieldModel { get }

    var delegate: BTFieldDelegate? { get set }

    func loadModel(_ model: BTFieldModel, layout: BTFieldLayout)
    
    func updateModelInEditing(_ model: BTFieldModel, layout: BTFieldLayout)
}

extension BTFieldModelLoadable {
    func updateModelInEditing(_ model: BTFieldModel, layout: BTFieldLayout) {}
}

protocol BTFieldCellProtocol: BTFieldModelLoadable {
    
    var fieldID: String { get }
    
    func updateBorderMode(_ mode: BorderMode)
    func updateContainerHighlight(_ highlight: Bool)
    func updateDescriptionButton(toSelected selected: Bool)
}

extension BTFieldCellProtocol {
    var fieldID: String { fieldModel.fieldID }
}

protocol BTFieldProgressCellProtocol: BTFieldCellProtocol {
    
    func panelDidStartEditing()
    
    func updateEditingStatus(_ editing: Bool)
    
    func reloadData()
    
    func stopEditing()
}

protocol BTFieldLinkCellProtocol: BTFieldCellProtocol {
    
    var linkedRecords: [BTRecordModel] { get }
    
    func panelDidStartEditing()
    func stopEditing()
}

protocol BTFieldTextCellProtocol: BTFieldCellProtocol {
    
    var textView: BTTextView { get }
    
    var cursorBootomOffset: CGFloat { get }
    func setCursorBootomOffset()
    
    var heightOfContentAboveKeyBoard: CGFloat { get set }
    
    func stopEditing()
    func resetTypingAttributes()
}

protocol BTFieldNumberCellProtocol: BTFieldTextCellProtocol {
    var commonTrackParams: [String: Any]? { get set }
    
    func reloadData()
}

protocol BTFieldURLCellProtocol: BTFieldTextCellProtocol {
    
}

protocol BTFieldPhoneCellProtocol: BTFieldTextCellProtocol {
    func startEditing()
}

protocol BTFieldLocationCellProtocol: BTFieldTextCellProtocol {
    var isClickDeleteMenuItem: Bool { get set }
}

protocol BTFieldRatingCellProtocol: BTFieldCellProtocol {
    func stopEditing()
    func panelDidStartEditing()
}

extension BTFieldTextCellProtocol {
    func resetTypingAttributes() { }
}

protocol BTFieldOptionCellProtocol: BTFieldCellProtocol {
    func stopEditing(scrollPosition: UICollectionView.ScrollPosition?)
    func panelDidStartEditing()
}

protocol BTFieldChatterCellProtocol: BTFieldCellProtocol {
    var addedMembers: [BTCapsuleModel] { get }
    var chatterType: BTChatterType { get }
    func stopEditing()
    func panelDidStartEditing()
}

protocol BTFieldDateCellProtocol: BTFieldCellProtocol {
    func stopEditing()
    func panelDidStartEditing()
}

protocol BTFieldAttachmentCellProtocol: BTFieldCellProtocol {
    var onlyCamera: Bool { get }
    var sourceAddView: UIView { get }
    var sourceAddRect: CGRect { get }
    func stopEditing()
    func panelDidStartEditing()
}

protocol BTFieldUIData: Equatable {
    
}

extension BTFieldUIData {
    /// UIModel 的 Equal 默认只比较 DataModel
    static func == (lhs: Self, rhs: Self) -> Bool {
        true
    }
}


