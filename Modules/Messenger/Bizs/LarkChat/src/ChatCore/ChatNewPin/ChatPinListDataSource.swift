//
//  ChatPinListDataSource.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/8/15.
//

import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkModel
import LKCommonsLogging
import LarkMessageCore
import LarkSDKInterface
import RustPB
import ByteWebImage
import UniverseDesignActionPanel
import UniverseDesignToast
import UniverseDesignIcon
import EENavigator
import LarkMessengerInterface

enum ChatPinCellVMType: Equatable {
    case pinCell(ChatPinCardContainerCellViewModel)
    case oldTip(ChatPinTipCellViewModel)
    case stickTip(ChatPinTipCellViewModel)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.pinCell(cellVM1), .pinCell(cellVM2)):
            return cellVM1.metaModel.pin.id == cellVM2.metaModel.pin.id
        case (.oldTip, .oldTip):
            return true
        case (.stickTip, .stickTip):
            return true
        default:
            return false
        }
    }

    func isGreater(cellVMType: ChatPinCellVMType, areInIncreasingOrder: (ChatPin, ChatPin) -> Bool) -> Bool {
        switch (self, cellVMType) {
        case let (.pinCell(cellVM1), .pinCell(cellVM2)):
            return areInIncreasingOrder(cellVM1.metaModel.pin, cellVM2.metaModel.pin)
        case (.pinCell, .stickTip):
            return true
        case (.stickTip, .pinCell):
            return false
        case (.pinCell(let cellVM), .oldTip):
            return !cellVM.pin.isOld
        case (.oldTip, .pinCell(let cellVM)):
            return cellVM.pin.isOld
        default:
            return false
        }
    }

    var cardCellViewModel: ChatPinCardContainerCellViewModel? {
        switch self {
        case .pinCell(let cellVM):
            return cellVM
        default:
            return nil
        }
    }

    var cellViewModel: ChatPinCardContainerCellAbility {
        switch self {
        case .pinCell(let cellVM):
            return cellVM
        case .oldTip(let cellVM):
            return cellVM
        case .stickTip(let cellVM):
            return cellVM
        }
    }

}

final class ChatPinListDataSource {
    private let logger = Logger.log(ChatPinListDataSource.self, category: "Module.IM.ChatPin")

    private(set) var cellVMTypes: [ChatPinCellVMType] = []

    private let getChat: () -> Chat
    private let chatId: String
    private let cellVMTransformer: (ChatPinCardCellMetaModel) -> ChatPinCardContainerCellViewModel?
    private let areInIncreasingOrder: (ChatPin, ChatPin) -> Bool
    private let enableOldTip: Bool

    init(getChat: @escaping () -> Chat,
         cellVMTransformer: @escaping (ChatPinCardCellMetaModel) -> ChatPinCardContainerCellViewModel?,
         areInIncreasingOrder: @escaping (ChatPin, ChatPin) -> Bool,
         enableOldTip: Bool) {
        self.getChat = getChat
        self.chatId = getChat().id
        self.cellVMTransformer = cellVMTransformer
        self.areInIncreasingOrder = areInIncreasingOrder
        self.enableOldTip = enableOldTip
    }

    @discardableResult
    func removeLast() -> Bool {
        if self.cellVMTypes.isEmpty {
            return false
        } else {
            self.cellVMTypes.removeLast()
            return true
        }
    }

    func hasStickTip() -> Bool {
        return self.cellVMTypes.contains(where: {
            switch $0 {
            case .stickTip:
                return true
            default:
                return false
            }
        })
    }

    func checkOldTipIsFirst() -> Bool {
        if let cellVMType = self.cellVMTypes.first,
           case .oldTip = cellVMType {
            return true
        } else {
            return false
        }
    }

    func removePins(_ pinIds: [Int64]) -> Bool {
        var pinIdsForDelete: String = ""
        var hasRemove = false
        pinIds.forEach { pinId in
            if let index = self.cellVMTypes.firstIndex(where: { (cellVM) -> Bool in
                return cellVM.cardCellViewModel?.metaModel.pin.id == pinId
            }) {
                self.cellVMTypes.remove(at: index)
                hasRemove = true
                pinIdsForDelete += " \(pinId)"
            }
        }
        let stickTipChange = self.handleStickTip()
        let oldTipChange = self.handleOldTip()
        self.logger.info("chatPinCardTrace dataSource delete chatId: \(self.chatId) pinIds: \(pinIdsForDelete) \(stickTipChange) \(oldTipChange)")
        return hasRemove || stickTipChange || oldTipChange
    }

    @discardableResult
    func merge(pins: [ChatPin]) -> Bool {
        let oldPinCellVMTypes = self.cellVMTypes
        var updatePins: Bool = false
        let chat = self.getChat()
        pins.forEach { pinModel in
            let metaModel = ChatPinCardCellMetaModel(
                getChat: { [weak self] in
                    return self?.getChat() ?? chat
                },
                pin: pinModel
            )
            if let cellVMType = self.cellVMTypes.first(where: { $0.cardCellViewModel?.metaModel.pin.id == pinModel.id }),
               let cardCellViewModel = cellVMType.cardCellViewModel {
                cardCellViewModel.update(metaModel)
                updatePins = true
            } else if let cellVM = self.cellVMTransformer(metaModel) {
                self.cellVMTypes.append(.pinCell(cellVM))
            }
        }
        /// 排序
        self.reorder()
        let stickTipChange = self.handleStickTip()
        let oldTipChange = self.handleOldTip()
        /// 判断 pin 是否被更新 || cellVMTypes 有变更
        return updatePins || stickTipChange || oldTipChange || oldPinCellVMTypes != self.cellVMTypes
    }

    func reset(pins: [ChatPin]) {
        var pinIdToCellVM: [Int64: ChatPinCardContainerCellViewModel] = [:]
        self.cellVMTypes.forEach { cellVM in
            guard let cardCellViewModel = cellVM.cardCellViewModel else { return }
            pinIdToCellVM[cardCellViewModel.metaModel.pin.id] = cardCellViewModel
        }
        self.cellVMTypes = []
        let chat = self.getChat()
        pins.forEach { pin in
            let metaModel = ChatPinCardCellMetaModel(
                getChat: { [weak self] in
                    return self?.getChat() ?? chat
                },
                pin: pin
            )
            if let cellVM = pinIdToCellVM[pin.id] {
                cellVM.update(metaModel)
                self.cellVMTypes.append(.pinCell(cellVM))
            } else if let cellVM = self.cellVMTransformer(metaModel) {
                self.cellVMTypes.append(.pinCell(cellVM))
            }
        }

        self.handleStickTip()
        self.handleOldTip()

    }

    @discardableResult
    private func reorder() -> Bool {
        let oldPinCellVMTypes = self.cellVMTypes
        self.cellVMTypes.sort { cellVMType1, cellVMType2 in
            return cellVMType1.isGreater(cellVMType: cellVMType2, areInIncreasingOrder: self.areInIncreasingOrder)
        }
        return oldPinCellVMTypes != self.cellVMTypes
    }

    @discardableResult
        private func handleStickTip() -> Bool {
            guard enableOldTip else { return false }
            self.logger.info("chatPinCardTrace dataSource stickTip begign handle chatId: \(self.chatId)")
            if let index = self.cellVMTypes.lastIndex(where: { $0.cardCellViewModel?.metaModel.pin.isTop ?? false }) {
                let curIndex = index + 1
                if curIndex < self.cellVMTypes.count,
                   case .stickTip = self.cellVMTypes[curIndex] {
                    self.logger.info("chatPinCardTrace dataSource stickTip already exist chatId: \(self.chatId)")
                    return false
                } else {
                    self.cellVMTypes.insert(.stickTip(ChatPinTipCellViewModel(title: BundleI18n.LarkChat.Lark_IM_NewPin_PrioritizedAbove_Text)), at: curIndex)
                    self.logger.info("chatPinCardTrace dataSource stickTip insert index: \(curIndex) chatId: \(self.chatId)")
                    return true
                }

            } else if let index = self.cellVMTypes.firstIndex(where: {
                switch $0 {
                case .stickTip:
                    return true
                default:
                    return false
                }
            }) {
                self.cellVMTypes.remove(at: index)
                self.logger.info("chatPinCardTrace dataSource stickTip remove index: \(index) chatId: \(self.chatId)")
                return true
            } else {
                self.logger.info("chatPinCardTrace dataSource stickTip do not need chatId: \(self.chatId)")
                return false
            }
        }

        @discardableResult
        private func handleOldTip() -> Bool {
            guard enableOldTip else { return false }
            self.logger.info("chatPinCardTrace dataSource oldTip begign handle chatId: \(self.chatId)")
            if let index = self.cellVMTypes.firstIndex(where: { $0.cardCellViewModel?.metaModel.pin.isOld ?? false }) {
                let preIndex = index - 1
                if preIndex >= 0,
                   case .oldTip = self.cellVMTypes[preIndex] {
                    self.logger.info("chatPinCardTrace dataSource oldTip already exist chatId: \(self.chatId)")
                    return false
                } else {
                    self.cellVMTypes.insert(.oldTip(ChatPinTipCellViewModel(title: BundleI18n.LarkChat.Lark_IM_NewPin_EarlierPinnedBelow_Text)), at: index)
                self.logger.info("chatPinCardTrace dataSource oldTip insert index: \(index) chatId: \(self.chatId)")
                return true
            }
        } else if let index = self.cellVMTypes.firstIndex(where: {
            switch $0 {
            case .oldTip:
                return true
            default:
                return false
            }
        }) {
            self.cellVMTypes.remove(at: index)
            self.logger.info("chatPinCardTrace dataSource oldTip remove index: \(index) chatId: \(self.chatId)")
            return true
        } else {
            self.logger.info("chatPinCardTrace dataSource oldTip do not need chatId: \(self.chatId)")
            return false
        }
    }

    func moveAfter(_ prevPinID: Int64?, movedPinID: Int64) -> Bool {
        self.logger.info("""
            chatPinCardTrace dataSource moveAfter start chatId: \(self.chatId)
            totalCount: \(self.cellVMTypes.count)
            prevPinID: \(prevPinID ?? -1)
            movedPinID: \(movedPinID)
        """)
        if let moveIndex = self.cellVMTypes.firstIndex(where: { $0.cardCellViewModel?.metaModel.pin.id == movedPinID }) {
            self.logger.info("chatPinCardTrace dataSource moveAfter chatId: \(self.chatId) moveIndex: \(moveIndex)")
            if let prevPinID = prevPinID {
                let itemToMove = self.cellVMTypes.remove(at: moveIndex)
                if let prevIndex = self.cellVMTypes.firstIndex(where: { $0.cardCellViewModel?.metaModel.pin.id == prevPinID }) {
                    self.cellVMTypes.insert(itemToMove, at: prevIndex + 1)
                    self.logger.info("chatPinCardTrace dataSource moveAfter chatId: \(self.chatId) success")
                    return true
                } else {
                    self.cellVMTypes.insert(itemToMove, at: moveIndex)
                    self.logger.info("chatPinCardTrace dataSource moveAfter chatId: \(self.chatId) prevPinID: \(prevPinID) not found and revert movedPin")
                    return false
                }
            } else {
                let itemToMove = self.cellVMTypes.remove(at: moveIndex)
                self.cellVMTypes.insert(itemToMove, at: 0)
                return true
            }
        } else {
            self.logger.info("chatPinCardTrace dataSource moveAfter chatId: \(self.chatId) movedPinID: \(movedPinID) not found")
            return false
        }
    }

    func update(doUpdate: (ChatPin) -> ChatPin?) -> Bool {
        var pinIdsForLog: String = ""
        var needUpdate = false
        let chat = self.getChat()
        for cellVM in self.cellVMTypes {
            guard let cardCellViewModel = cellVM.cardCellViewModel else {
                continue
            }
            let pinModel = cardCellViewModel.metaModel.pin
            if let newPinModel = doUpdate(pinModel) {
                cardCellViewModel.update(ChatPinCardCellMetaModel(
                    getChat: { [weak self] in
                        return self?.getChat() ?? chat
                    },
                    pin: newPinModel
                ))
                needUpdate = true
                pinIdsForLog += " \(pinModel.id)"
            }
        }
        if needUpdate {
            self.reorder()
        }
        self.logger.info("chatPinCardTrace dataSource doUpdate chatId: \(self.chatId) pinIds: \(pinIdsForLog)")
        return needUpdate
    }

    func calculateSize(pinId: Int64) -> Int? {
        if let index = self.cellVMTypes.firstIndex(where: { $0.cardCellViewModel?.metaModel.pin.id == pinId }) {
            let cellVMType = self.cellVMTypes[index]
            cellVMType.cellViewModel.layout()
            return index
        }
        return nil
    }

    func calculateSize(shouldUpdate: (_ pinId: Int64, _ payload: ChatPinPayload?) -> Bool) -> Int? {
        if let index = self.cellVMTypes.firstIndex(where: {
            guard let metaModel = $0.cardCellViewModel?.metaModel else { return false }
            return shouldUpdate(metaModel.pin.id, metaModel.pin.payload)
        }) {
            let cellVMType = self.cellVMTypes[index]
            cellVMType.cellViewModel.layout()
            return index
        }
        return nil
    }

    func layout() {
        self.cellVMTypes.forEach { $0.cellViewModel.layout() }
    }

    func onResize() {
        for cellVMType in self.cellVMTypes {
            cellVMType.cellViewModel.onResize()
        }
    }
}
