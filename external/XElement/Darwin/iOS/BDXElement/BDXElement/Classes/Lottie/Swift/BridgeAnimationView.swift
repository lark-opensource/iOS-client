//
//  BridgeAnimationView.swift
//  LMBridgeLottie
//
//  Created by AKing on 2020/8/9.
//
import Foundation
import LottieSwift

@objc
public protocol BridgeAnimationViewProtocol {
    func setAnimationFromJSONData(_ jsonData: Data)
    func loopAnimation(_ loop: Bool)
    func play(_ completion: @escaping (Bool) -> Void)
    func stop()
    func pause()
    func setProgressWith(frame: NSNumber)
    var animationSpeed: CGFloat { get set }
}

@objc
public class BridgeAnimationView: UIView {
    private var animationView: AnimationView?
    
    private var shouldPlayAfterSettingJson = false
    private var loopMode: LottieLoopMode = .loop
    private var completion: ((Bool) -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BridgeAnimationView: BridgeAnimationViewProtocol {
    public func setProgressWith(frame: NSNumber) {
        //TODO: hanzheng
    }
        
    public func pause() {
        animationView?.pause()
    }
    
    public var animationSpeed: CGFloat {
        get {
            animationView?.animationSpeed ?? 0
        }
        set {
            animationView?.animationSpeed = newValue
        }
    }
    
    public func setAnimationFromJSONData(_ jsonData: Data) {
        do {
            
          let animation = try JSONDecoder().decode(Animation.self, from: jsonData)
            if animationView == nil {
                animationView = AnimationView(animation: animation)
                animationView?.loopMode = loopMode
                guard let lottieView = animationView else { return }
                lottieView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(lottieView)
                let left = NSLayoutConstraint(item: lottieView,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .left,
                                              multiplier: 1.0, constant: 0)
                left.isActive = true
                let right = NSLayoutConstraint(item: lottieView,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .right,
                                              multiplier: 1.0, constant: 0)
                right.isActive = true
                let top = NSLayoutConstraint(item: lottieView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0, constant: 0)
                top.isActive = true
                let bottom = NSLayoutConstraint(item: lottieView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .bottom,
                                              multiplier: 1.0, constant: 0)
                bottom.isActive = true
                
                if shouldPlayAfterSettingJson, let completion = completion {
                    lottieView.loopMode = loopMode
                    play(completion)
                }
            }
        } catch {
          assert(false, "lottie json parser fail")
        }
    }
    
    public func loopAnimation(_ loop: Bool) {
        loopMode = loop ? .loop : .playOnce
        animationView?.loopMode = loopMode
    }
    
    public func play(_ completion: @escaping (Bool) -> Void) {
        shouldPlayAfterSettingJson = animationView == nil
        if shouldPlayAfterSettingJson {
            self.completion = completion
        } else {
            self.completion = nil;
            animationView?.play {[weak self] (finished) in
                completion(finished)
            }
        }
    }
    
    public func stop() {
        animationView?.stop()
    }
    
    
}
