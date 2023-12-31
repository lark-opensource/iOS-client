//
//  SketchRemoteHandler.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/9.
//

import Foundation
import RxSwift

private typealias Action = SketchOperationUnit.Action
private typealias ActionV2 = SketchOperationUnit.ActionV2
extension SketchOperationUnit {
    static func newInstance() -> SketchOperationUnit {
        var unit = SketchOperationUnit()
        unit.timestampMs = Int64(Date().timeIntervalSince1970 * 1000)
        return unit
    }
}

extension SketchRemoveData.RemoveType {
    var rustType: RemoveType {
        return RemoveType(rawValue: UInt32(self.rawValue))
    }
}

extension RemoveType {
    var pbType: SketchRemoveData.RemoveType {
        return SketchRemoveData.RemoveType(rawValue: Int(self.rawValue)) ?? .removeByShapeID
    }
}

extension SketchRemoveData {

    func withTransportData<R>(body: (RemoveTransportData) throws -> R) rethrows -> R {
        let ids = self.ids.map { id -> UnsafePointer<Int8>? in
            UnsafePointer<Int8>(strdup(id))
        }

        let deviceIDs = self.users.map { user -> UnsafePointer<Int8>? in
            UnsafePointer<Int8>(strdup(user.deviceID))
        }
        let userIDs = self.users.map { user -> UnsafePointer<Int8>? in
            UnsafePointer<Int8>(strdup(user.userID))
        }

        let users = zip(self.users, zip(deviceIDs, userIDs))
            .map { (user, id2) -> SketchByteviewUserFFI in
            SketchByteviewUserFFI(device_id: id2.0, user_id: id2.1, user_type: UInt(user.userType.rawValue))
        }

        defer {
            for id in ids {
                free(UnsafeMutableRawPointer(mutating: id))
            }
            for id in deviceIDs {
                free(UnsafeMutableRawPointer(mutating: id))
            }
            for id in userIDs {
                free(UnsafeMutableRawPointer(mutating: id))
            }
        }
        func capture(ids: UnsafePointer<UnsafePointer<Int8>?>,
                     idCount: UInt,
                     users: UnsafePointer<SketchByteviewUserFFI>?,
                     userCount: UInt) throws -> R {
            let data = RemoveTransportData(remove_type: self.removeType.rustType,
                                           ids_ptr: ids,
                                           ids_len: idCount,
                                           users_ptr: users,
                                           users_len: userCount,
                                           current_step: UInt(self.currentStep))
            return try body(data)
        }
        return try capture(ids: ids,
                           idCount: UInt(ids.count),
                           users: users,
                           userCount: UInt(users.count))
    }
}

protocol SketchRemoteHandlerDelegate: AnyObject {
    var drawRemoteShapeEnable: Bool { get }
    func didAddSelfShape(id: ShapeID)
    func didRemoveShape(id: ShapeID)
    func selfShapeContains(id: ShapeID) -> Bool
    func changeUndoStatus(canUndo: Bool)
}

class SketchRemoteHandler: SketchNicknameHandler {

    var decorateLayers: [CALayer] {
        [cometHandler.cometLayer]
    }

    private let drawboard: DrawBoard
    private let pencilHandler: SketchPencilHandler
    private let cometHandler: SketchCometHandler
    private let sketch: RustSketch
    private let disposeBag = DisposeBag()
    weak var delegate: SketchRemoteHandlerDelegate?

    init(drawboard: DrawBoard,
         sketch: RustSketch,
         meeting: InMeetMeeting) {
        self.drawboard = drawboard
        self.sketch = sketch
        self.cometHandler = SketchCometHandler(sketch: sketch, meeting: meeting)
        self.pencilHandler = SketchPencilHandler(sketch: sketch, drawboard: drawboard, meeting: meeting)
        super.init(meeting: meeting)
    }

    func handle(fetchedUnits: [SketchDataUnit]) {
        for unit in fetchedUnits {
            addSketchUnit(unit: unit, fromFetch: true)
        }
    }

    func handle(sketchOperation: SketchOperationUnit) {
        assert(Thread.isMainThread)
        ByteViewSketch.logger.info("handle unit: \(sketchOperation.briefDescription)")
        switch sketchOperation.cmd {
        case .add:
            handleAddCmd(action: sketchOperation.actionV2,
                         sketchUnits: sketchOperation.sketchUnits)
        case .remove:
            handleRemoveCmd(action: sketchOperation.actionV2,
                            removeData: sketchOperation.removeData)
        @unknown default:
            break
        }
    }

    private func handleAddCmd(action: ActionV2, sketchUnits: [SketchDataUnit]) {
        for unit in sketchUnits {
            addSketchUnit(unit: unit, fromFetch: false)
        }
    }

    private func handleRemoveCmd(action: ActionV2, removeData: SketchRemoveData) {
        let orderedIDs = sketch.remove(removeData: removeData)
        let removedIDSet = drawboard.reorderDrawables(orderedIDs: orderedIDs)
        removedIDSet.forEach { self.delegate?.didRemoveShape(id: $0) }
        let canUndo = sketch.getUndoStatus()
        self.delegate?.changeUndoStatus(canUndo: canUndo)
    }

    func addSketchUnit(unit: SketchDataUnit, fromFetch: Bool) {
        switch unit.shapeType {
        case .pencil:
            process(pencil: unit, fromFetch: fromFetch)
        case .rectangle:
            process(rect: unit, fromFetch: fromFetch)
        case .comet:
            process(comet: unit)
        case .oval:
            process(oval: unit, fromFetch: fromFetch)
        case .arrow:
            process(arrow: unit, fromFetch: fromFetch)
        @unknown default:
            assertionFailure("unrecognized shapeType")
        }
    }

    func clearComet() {
        cometHandler.clearContext()
    }

    private func process(arrow: SketchDataUnit, fromFetch: Bool) {
        guard delegate?.selfShapeContains(id: arrow.shapeID) != true else {
            return
        }
        guard let drawable = sketch.receive(arrow: arrow) else {
            return
        }
        if (delegate?.drawRemoteShapeEnable ?? true) || fromFetch {
            if drawboard.addRemote(drawable: drawable) {
                let belongsToSelf = arrow.user.identifier == sketch.user.identifier
                if belongsToSelf {
                    delegate?.didAddSelfShape(id: arrow.shapeID)
                }
                if !fromFetch {
                    addNickname(with: arrow.user.vcType,
                                shapeID: arrow.shapeID,
                                position: CGPoint(x: drawable.end.x + 3, y: drawable.end.y))
                }
            }
        }
    }

    private func addNickname(with user: ByteviewUser, shapeID: ShapeID, position: CGPoint) {
        singleNicknameDrawable(with: user, shapeID: shapeID, position: position) { [weak self] drawable in
            self?.drawboard.updateNickname(drawable: drawable)
        }
    }

    private func process(pencil: SketchDataUnit, fromFetch: Bool) {
        let belongsToSelf = pencil.user.identifier == sketch.user.identifier
        if (delegate?.drawRemoteShapeEnable ?? true) || fromFetch {
            if fromFetch && pencil.pencil.finish {
                var unit = pencil
                unit.pencil.duration = 0
                let shouldDraw = sketch.receive(pencil: unit)
                if shouldDraw {
                    _ = sketch.getPencilSnippet()
                    let shapeID = pencil.shapeID
                    let drawable = sketch.getPencilBy(id: shapeID)
                    drawboard.updateRemote(pencil: drawable)
                }
            } else {
                pencilHandler.start(unit: pencil)
            }
            if belongsToSelf {
                delegate?.didAddSelfShape(id: pencil.shapeID)
            }
        } else {
            if pencil.pencil.finish {
                var unit = pencil
                unit.pencil.duration = 0
                sketch.receive(pencil: unit)
                if belongsToSelf {
                    delegate?.didAddSelfShape(id: pencil.shapeID)
                }
            }
        }
    }

    private func process(oval: SketchDataUnit, fromFetch: Bool) {
        guard let drawable = sketch.receive(oval: oval) else {
            return
        }
        if (delegate?.drawRemoteShapeEnable ?? true) || fromFetch {
            if drawboard.addRemote(drawable: drawable) {
                let belongsToSelf = oval.user.identifier == sketch.user.identifier
                if belongsToSelf {
                    delegate?.didAddSelfShape(id: oval.shapeID)
                }
                if !fromFetch {
                    addNickname(with: oval.user.vcType,
                                shapeID: oval.shapeID,
                                position: CGPoint(x: drawable.frame.maxX + 3,
                                                  y: drawable.frame.maxY - drawable.frame.size.height / 2))
                }
            }
        }
    }

    private func process(comet: SketchDataUnit) {
        if delegate?.drawRemoteShapeEnable ?? true {
            cometHandler.start(data: comet)
        }
    }

    private func process(rect: SketchDataUnit, fromFetch: Bool) {
        guard let drawable = sketch.receive(rectangle: rect) else {
            return
        }
        if (delegate?.drawRemoteShapeEnable ?? true) || fromFetch {
            if drawboard.addRemote(drawable: drawable) {
                let belongsToSelf = rect.user.identifier == sketch.user.identifier
                if belongsToSelf {
                    delegate?.didAddSelfShape(id: rect.shapeID)
                }
                if !fromFetch {
                    addNickname(with: rect.user.vcType,
                                shapeID: rect.shapeID,
                                position: CGPoint(x: drawable.frame.maxX + 3, y: drawable.frame.maxY - drawable.frame.height / 2))
                }
            }
        }
    }
}
