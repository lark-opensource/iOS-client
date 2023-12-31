import UIKit

public struct DraggingConfig {
    public var insets: UIEdgeInsets
    public var floatingSize: CGSize
    public var initialUnitCoord: CGPoint

    public static let `default` = DraggingConfig(insets: UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0),
                                                 floatingSize: CGSize(width: 90.0, height: 90.0),
                                                 initialUnitCoord: CGPoint(x: 1.0, y: 0.0))
}

public extension UIView {
    func presentFloatingView(view: UIView, config: DraggingConfig = .default) -> DragbleHandle {
        self.addSubview(view)
        let handle = DragbleHandle()
        handle.floatingSize = config.floatingSize
        handle.floatingInsets = config.insets
        handle.setup(floatingView: view)
        handle.resetInitialConstraints()
        return handle
    }
}

public func setupFloatingDrag(view: UIView, config: DraggingConfig = .default) -> DragbleHandle {
    let handle = DragbleHandle()
    handle.floatingSize = config.floatingSize
    handle.floatingInsets = config.insets
    handle.setup(floatingView: view)
    handle.resetInitialConstraints()
    return handle
}

public final class DragbleHandle: NSObject {
    private weak var view: UIView?
    private var gest: UIPanGestureRecognizer?

    private var boundsObservation: NSKeyValueObservation?
    private var subviewsObservation: NSKeyValueObservation?
    private var safeAreaInsetsObservation: NSKeyValueObservation?

    public var floatingSize = CGSize.zero {
        didSet {
            guard self.floatingSize != oldValue else {
                return
            }
            self.layout()
        }
    }

    private var unitCoord = CGPoint.zero {
        didSet {
            guard self.unitCoord != oldValue else {
                return
            }
            self.layout()
        }
    }

    fileprivate override init() {
        super.init()
    }

    private var containerBounds = CGRect.zero {
        didSet {
            guard self.containerBounds != oldValue else {
                return
            }
            self.layout()
        }
    }

    private var containerSafeAreaInsets = UIEdgeInsets.zero {
        didSet {
            guard self.containerSafeAreaInsets != oldValue else {
                return
            }
            self.layout()
        }
    }

    public var floatingInsets = UIEdgeInsets.zero {
        didSet {
            guard self.floatingInsets != oldValue else {
                return
            }
            self.layout()
        }
    }

    public func translate(offset: CGPoint) {
        var newCoord = self.unitCoord
        let floatingRegion = self.floatingRegion
        if floatingRegion.width > floatingSize.width {
            newCoord.x += offset.x / (floatingRegion.width - floatingSize.width)
        }
        if floatingRegion.height > floatingSize.height {
            newCoord.y += offset.y / (floatingRegion.height - floatingSize.height)
        }
        self.unitCoord = newCoord
    }

    private var floatingRegion: CGRect {
        containerBounds
        .inset(by: containerSafeAreaInsets)
        .inset(by: floatingInsets)
    }


    private func convertToUnitCoord(origin: CGPoint) -> CGPoint {
        let floatingRegion = self.floatingRegion
        guard floatingRegion.width >= floatingSize.width && floatingRegion.height >= floatingSize.height else {
            return .zero
        }
        let unitX = (origin.x - floatingRegion.origin.x) / (floatingRegion.width - floatingSize.width)
        let unitY = (origin.y - floatingRegion.origin.y) / (floatingRegion.height - floatingSize.height)
        return CGPoint(x: unitX, y: unitY)
    }

    private func layout() {
        let floatingRegion = self.floatingRegion
        guard containerBounds.width >= 1.0 && containerBounds.height >= 1.0,
        floatingRegion.width > floatingSize.width,
        floatingRegion.height > floatingSize.height else {
            return
        }

        let unitX: CGFloat
        let unitY: CGFloat
        if self.isDragging {
            unitX = unitCoord.x
            unitY = unitCoord.y
        } else {
            unitX = min(max(unitCoord.x, 0.0), 1.0)
            unitY = min(max(unitCoord.y, 0.0), 1.0)
        }

        var floatingOrigin = floatingRegion.origin
        floatingOrigin.x += (floatingRegion.width - floatingSize.width) * unitX
        floatingOrigin.y += (floatingRegion.height - floatingSize.height) * unitY
        self.view?.frame = CGRect(origin: floatingOrigin, size: floatingSize)
    }

    fileprivate func setup(floatingView: UIView) {
        assert(self.view == nil && gest == nil)
        self.view = floatingView
        floatingView.autoresizingMask = []
        let panGest = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gest:)))
        floatingView.addGestureRecognizer(panGest)
        self.gest = panGest

        if let superview = view?.superview {
            self.boundsObservation = superview.layer.observe(\.bounds, options: [.initial, .new]) { [weak self] _, change in
                guard let self = self else {
                    return
                }
                self.containerBounds = change.newValue ?? .zero
            }

            self.subviewsObservation = superview.layer.observe(\.sublayers, options: [.new]) { [weak self] _, change in
                guard let floatingView = self?.view else {
                    return
                }
                if change.kind == .setting {
                    floatingView.superview?.bringSubviewToFront(floatingView)
                }
            }

            self.safeAreaInsetsObservation =
            superview.observe(\.safeAreaInsets, options: [.initial, .new]) { [weak self] _, change in
                guard change.oldValue != change.newValue,
                let self = self else {
                    return
                }
                self.containerSafeAreaInsets = change.newValue ?? .zero
            }
        }
    }

    deinit {
        invalidate()
    }

    public var isDragging: Bool {
        if let gest = self.gest {
            return gest.state != .possible &&
            gest.state != .ended &&
            gest.state != .cancelled &&
            gest.state != .failed
        } else {
            return false
        }
    }

    public func invalidate() {
        guard let gest = self.gest,
        let view = self.view else {
            return
        }
        view.removeGestureRecognizer(gest)

        self.safeAreaInsetsObservation?.invalidate()
        self.boundsObservation?.invalidate()
        self.subviewsObservation?.invalidate()
        self.safeAreaInsetsObservation = nil
        self.boundsObservation = nil
        self.subviewsObservation = nil

        self.view = nil
        self.gest = nil
    }


    @objc
    private func handlePanGesture(gest: UIPanGestureRecognizer) {
        guard let superview = gest.view?.superview else {
            return
        }
        switch gest.state {
        case .began:
            break
        case .changed:
            let translation = gest.translation(in: superview)
            self.applyDragTranslation(translation: translation)
            gest.setTranslation(.zero, in: superview)
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0,
                           options: [], animations: {
                               self.unitCoord.x = self.unitCoord.x < 0.5 ? 0.0 : 1.0
                               self.layout()
                           })
        default:
            break
        }
    }


    private func applyDragTranslation(translation: CGPoint) {
        guard let floatingFrame = self.view?.frame else {
            return
        }

        let dragRegion = self.containerBounds.inset(by: floatingInsets)
        var translation = translation
        if floatingFrame.maxX + translation.x > dragRegion.maxX {
            translation.x = dragRegion.maxX - floatingFrame.maxX
        } else if floatingFrame.minX + translation.x < dragRegion.minX {
            translation.x = dragRegion.minX - floatingFrame.minX
        }

        if floatingFrame.maxY + translation.y > dragRegion.maxY {
            translation.y = dragRegion.maxY - floatingFrame.maxY
        } else if floatingFrame.minY + translation.y < dragRegion.minY {
            translation.y = dragRegion.minY - floatingFrame.minY
        }
        self.unitCoord = self.convertToUnitCoord(origin: CGPoint(x: floatingFrame.origin.x + translation.x,
                                                                 y: floatingFrame.origin.y + translation.y))
    }


    public func resetInitialConstraints() {
        guard let floatingView = self.view,
        let superview = floatingView.superview else {
            return
        }

        self.containerBounds = superview.bounds
        self.floatingInsets = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 12.0, right: 12.0)
        self.containerSafeAreaInsets = superview.safeAreaInsets
        self.unitCoord = CGPoint(x: 1.0, y: 0.0)
    }
}
