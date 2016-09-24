//
//  TwicketLoader.swift
//  Twicket
//
//  Created by Pol Quintana on 7/11/15.
//  Copyright © 2015 Pol Quintana. All rights reserved.
//

import UIKit

public class TwicketLoader: UIView, CAAnimationDelegate {
    
    enum AnimationKeys: String {
        case arc1
        case arc2
        case arc3
    }
    
    private var animate: Bool = false
    private static let size: CGFloat = 50
    private let lineWidth: CGFloat = 3
    private var radiusDiff: CGFloat { return self.frameHeight/5 }
    private var rotateDuration1: TimeInterval = 1.25
    private var rotateDuration2: TimeInterval = 1.0
    private var rotateDuration3: TimeInterval = 1.15
    private var arc1: CAShapeLayer = CAShapeLayer()
    private var arc2: CAShapeLayer = CAShapeLayer()
    private var arc3: CAShapeLayer = CAShapeLayer()
    
    private init(empty: Bool = false, size: CGFloat) {
        let viewFrame = CGRect(x: 0, y: 0, width: size, height: size)
        super.init(frame: viewFrame)
        configure(withSize: size, empty: empty)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure(withSize: frameHeight, empty: false)
    }
    
    private func configure(withSize size: CGFloat, empty: Bool) {
        let viewFrame = CGRect(x: 0, y: 0, width: size, height: size)
        let angleWidth = empty ? 0 : CGFloat(M_PI_2)
        let center = CGPoint(x: size/2, y: size/2)
        arc1 = TwicketLoader.arcLayer(radius: size/2 - 0*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.red)
        arc2 = TwicketLoader.arcLayer(radius: size/2 - 1*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.blue)
        arc3 = TwicketLoader.arcLayer(radius: size/2 - 2*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.yellow)
        
        [arc1, arc2, arc3].forEach {
            $0.frame = viewFrame
            layer.addSublayer($0)
        }
    }
    
    public static func createEmptyLoader(in view: UIView, size: CGFloat = size) -> TwicketLoader {
        let loader = TwicketLoader(empty: true, size: size)
        loader.center(in: view)
        view.addSubview(loader)
        return loader
    }
    
    public static func createLoader(in view: UIView, size: CGFloat = size) -> TwicketLoader {
        let loader = TwicketLoader(size: size)
        loader.isHidden = true
        loader.alpha = 0.0
        loader.center(in: view)
        view.addSubview(loader)
        return loader
    }
    
    public func showLoader(_ animated: Bool = true) {
        if animate { return }
        animate = true
        let animations = { self.alpha = 1.0 }
        if animated {
            UIView.animate(withDuration: 0.5, animations: animations)
        }
        else {
            animations()
        }
        isHidden = false
        rotateArc1()
        rotateArc2()
        rotateArc3()
    }
    
    public func hideLoader(_ animated: Bool = true, completion: (() -> ())? = nil) {
        let animations = { self.alpha = 0.0 }
        let removeLoader: (Bool) -> () = { completed in
            self.isHidden = true
            self.cancelAnimations()
            completion?()
        }
        
        if !animated {
            animations()
            removeLoader(true)
            return
        }
        UIView.animate(withDuration: 0.5, animations: animations, completion: removeLoader)
    }
    
    public func removeLoader(animated: Bool = true) {
        hideLoader(animated) {
            self.removeFromSuperview()
        }
    }
    
    public func advance(to progress: CGFloat) {
        let maxValue = CGFloat(2*M_PI)
        let angleWidth = maxValue*progress
        if angleWidth > maxValue { return }
        UIView.animate(withDuration: 0.5) {
            self.arc1.path = TwicketLoader.arcPath(radius: self.frameHeight/2 - 0*self.radiusDiff,
                angleWidth: angleWidth,
                center: CGPoint(x: self.frameWidth/2, y: self.frameHeight/2))
            self.arc2.path = TwicketLoader.arcPath(radius: self.frameHeight/2 - 1*self.radiusDiff,
                angleWidth: angleWidth,
                center: CGPoint(x: self.frameWidth/2, y: self.frameHeight/2),
                inverse: true)
            self.arc3.path = TwicketLoader.arcPath(radius: self.frameHeight/2 - 2*self.radiusDiff,
                angleWidth: angleWidth,
                center: CGPoint(x: self.frameWidth/2, y: self.frameHeight/2))
        }
    }
    
    private func cancelAnimations() {
        animate = false
        arc1.removeAllAnimations()
        arc2.removeAllAnimations()
        arc3.removeAllAnimations()
    }
    
    
    //MARK: Rotation
    
    private func rotateArc1() {
        rotate(arc1, withDuration: rotateDuration1, animation: AnimationKeys.arc1)
    }
    
    private func rotateArc2() {
        rotate(arc2, withDuration: rotateDuration2, animation: AnimationKeys.arc2)
    }
    
    private func rotateArc3() {
        rotate(arc3, withDuration: rotateDuration3, animation: AnimationKeys.arc3)
    }
    
    private func rotate(_ shape: CAShapeLayer, withDuration duration: TimeInterval, animation: AnimationKeys) {
        if !animate { return }
        let rotate = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        if animation != .arc2 {
            rotate.values = [0, M_PI, 2*M_PI-0.0001]
        }
        else {
            rotate.values = [0, -M_PI, -2*M_PI-0.0001]
        }
        rotate.duration = duration
        rotate.delegate = self
        rotate.setValue(animation.rawValue, forKey: "identifier")
        shape.add(rotate, forKey: "rotation")
    }
    
    private func randomAngle() -> CGFloat {
        return randomBetween(CGFloat(M_PI_2), and: CGFloat(M_PI_2)/3)
    }
    
    private func randomBetween(_ firstNum: CGFloat, and secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    
    //MARK: Animation delegate

    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard animate, let identifier = anim.value(forKey: "identifier") as? String else { return }
        if identifier == AnimationKeys.arc1.rawValue {
            rotateArc1()
        }
        else if identifier == AnimationKeys.arc2.rawValue {
            rotateArc2()
        }
        else if identifier == AnimationKeys.arc3.rawValue {
            rotateArc3()
        }
    }
    
    
    //MARK: Arc helper
    
    private static func arcLayer(radius: CGFloat, angleWidth: CGFloat, center: CGPoint, lineWidth: CGFloat, color: UIColor) -> CAShapeLayer {
        let progressRingLayer = CAShapeLayer()
        progressRingLayer.path = arcPath(radius: radius, angleWidth: angleWidth, center: center)
        progressRingLayer.lineWidth = lineWidth
        progressRingLayer.strokeColor = color.cgColor
        progressRingLayer.lineCap = kCALineCapRound
        progressRingLayer.fillColor = UIColor.clear.cgColor
        return progressRingLayer
    }
    
    private static func arcPath(radius: CGFloat, angleWidth: CGFloat, center: CGPoint, inverse: Bool = false) -> CGPath {
        let initialAngle = CGFloat(-M_PI_2)
        return UIBezierPath(arcCenter: center,
            radius: radius,
            startAngle: initialAngle,
            endAngle: inverse ? -angleWidth + initialAngle : angleWidth + initialAngle,
            clockwise: !inverse).cgPath
    }

}
