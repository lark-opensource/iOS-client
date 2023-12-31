//
//  LiveSettingPickedViewModel.swift
//  ByteView
//
//  Created by sihuahao on 2022/5/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

struct PickedData {
    var avatarKey: String
    var id: String
    var name: String
    var isChatter: Bool
    var isDepartment: Bool
}

protocol PickedViewModelDelegate: AnyObject {
    func reload()
}

class LiveSettingPickedViewModel {

    weak var delegate: PickedViewModelDelegate?

    let singleLineHeight: CGFloat = 34
    let doubleLineHeight: CGFloat = 64
    var pickedViewWidth: CGFloat
    var pickedViewHeight: CGFloat = 0

    var visibleCount: Int = 0
    var totalHeadCount: Int = 0
    var addOnHeadCount: Int = 0

    var pickedDatas: [PickedData] = []
    var membersData: [LivePermissionMember]?
    var selectedMembers: [LivePermissionMember] = []
    var visibleWidth: [CGFloat] = []

    var needMoreCell: Bool = false
    var privilegeChanged: Bool = false
    var isAllResigned: Bool?

    init(viewWidth: CGFloat) {
        self.pickedViewWidth = viewWidth
    }

    func configData(members: [LivePermissionMember], isFromInit: Bool, isAllResigned: Bool) {
        self.isAllResigned = isAllResigned
        if isAllResigned {

            resetToInitialStatus()
            configAllResignedData()
            configCellData(members: [])

        } else {
            if !isFromInit {
                if !privilegeChanged {
                    if pickedDataDidChanged(membersData ?? [], members) {
                        Toast.show(I18n.View_MV_ChangedSelectUser)
                    }
                } else {
                    Toast.show(I18n.View_MV_SpecificViewerThisLive_Toast)
                }
            }
            membersData = members
            resetToInitialStatus()
            configCellData(members: members)
        }
    }

    func configCellData(members: [LivePermissionMember]) {
        for item in members {
            switch item.memberType {
            case .memberTypeDepartment:
                pickedDatas.append(PickedData(avatarKey: "", id: item.memberId, name: item.memberName?.zh_cn ?? "", isChatter: false, isDepartment: true))
                selectedMembers.append(item)
            case .memberTypeChat:
                if item.memberName != nil, let count = item.userCount, let key = item.avatarUrl {
                    totalHeadCount += Int(count)
                    pickedDatas.append(PickedData(avatarKey: key, id: item.memberId, name: item.memberName?.zh_cn ?? "", isChatter: false, isDepartment: false))
                    selectedMembers.append(item)
                }
            case .memberTypeUser:
                if item.memberName != nil, let count = item.userCount, let key = item.avatarUrl {
                    totalHeadCount += Int(count)
                    pickedDatas.append(PickedData(avatarKey: key, id: item.memberId, name: item.memberName?.zh_cn ?? "", isChatter: true, isDepartment: false))
                    selectedMembers.append(item)
                }
            default:
                break
            }
        }
        checkDataLayoutStyle()
        self.delegate?.reload()
    }

    func resetToInitialStatus() {
        pickedDatas = []
        visibleWidth = []
        selectedMembers = []
        needMoreCell = false
        visibleCount = 0
        totalHeadCount = 0
        addOnHeadCount = 0
    }

    func checkDataLayoutStyle() {
        var currentLine: Int = 0
        var tmpLineWidth: CGFloat = 0
        let itemSpace: CGFloat = 4
        let moreCellWidth: CGFloat = 33
        let totalItemCount = pickedDatas.count
        visibleCount = 0
        for item in pickedDatas {
            let textWidth: CGFloat = min(ceil(item.name.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]).width + 36), pickedViewWidth)
            if currentLine == 0 {
                pickedViewHeight = singleLineHeight
                addOnHeadCount = totalItemCount - visibleCount
                if tmpLineWidth == 0 {
                    tmpLineWidth = textWidth
                } else {
                    ///第一行放不下
                    if tmpLineWidth + itemSpace + textWidth > pickedViewWidth {
                      ///  第二行放不下
                        if textWidth + itemSpace + moreCellWidth > pickedViewWidth {
                            needMoreCell = true
                            visibleWidth.append(moreCellWidth)
                            if tmpLineWidth + itemSpace + moreCellWidth > pickedViewWidth {
                                currentLine = 1
                                pickedViewHeight = doubleLineHeight
                            }
                            return
                        }
                        currentLine = 1
                        tmpLineWidth = textWidth
                        pickedViewHeight = doubleLineHeight
                    } else {
                        tmpLineWidth += itemSpace + textWidth
                    }
                }
            } else if currentLine == 1 {
                pickedViewHeight = doubleLineHeight
                addOnHeadCount = totalItemCount - visibleCount
                if tmpLineWidth + itemSpace + moreCellWidth > pickedViewWidth {
                    needMoreCell = true
                    visibleCount -= 1
                    addOnHeadCount += 1
                    visibleWidth.removeLast()
                    visibleWidth.append(moreCellWidth)
                    return
                } else if tmpLineWidth + itemSpace + textWidth > pickedViewWidth - moreCellWidth - itemSpace {
                    needMoreCell = true
                    visibleWidth.append(moreCellWidth)
                    return
                } else {
                    tmpLineWidth += itemSpace + textWidth
                }
            }
            visibleWidth.append(textWidth)
            visibleCount += 1
        }
    }

    func pickedDataDidChanged(_ membersOrgin: [LivePermissionMember], _ membersComing: [LivePermissionMember]) -> Bool {
        if membersOrgin.count != membersComing.count { return true }
        for i  in 0..<membersOrgin.count {
            if membersOrgin[i].memberId != membersComing[i].memberId { return true }
        }
        return false
    }

    func configAllResignedData () {
        pickedDatas = [PickedData(avatarKey: "", id: "", name: I18n.View_MV_ViewerResigned, isChatter: true, isDepartment: false)]
    }
}
