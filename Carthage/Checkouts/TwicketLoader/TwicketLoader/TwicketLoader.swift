//
//  TwicketLoader.swift
//  Twicket
//
//  Created by Pol Quintana on 7/11/15.
//  Copyright © 2015 Pol Quintana. All rights reserved.
//

import UIKit

public class TwicketLoader: UIView {
    
    enum AnimationKeys: String {
        case arc1
        case arc2
        case arc3
    }
    
    private var animate: Bool = false
    private static let size: CGFloat = 50
    private let lineWidth: CGFloat = 3
    private var radiusDiff: CGFloat { return self.frameHeight/5 }
    private var rotateDuration1: NSTimeInterval = 1.25
    private var rotateDuration2: NSTimeInterval = 1.0
    private var rotateDuration3: NSTimeInterval = 1.15
    private var arc1: CAShapeLayer = CAShapeLayer()
    private var arc2: CAShapeLayer = CAShapeLayer()
    private var arc3: CAShapeLayer = CAShapeLayer()
    
    private init(empty: Bool = false, size: CGFloat) {
        let viewFrame = CGRect(x: 0, y: 0, width: size, height: size)
        super.init(frame: viewFrame)
        let angleWidth = empty ? 0 : CGFloat(M_PI_2)
        arc1 = TwicketLoader.arcLayer(radius: size/2 - 0*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.redColor())
        arc2 = TwicketLoader.arcLayer(radius: size/2 - 1*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.blueColor())
        arc3 = TwicketLoader.arcLayer(radius: size/2 - 2*radiusDiff, angleWidth: angleWidth, center: center, lineWidth: lineWidth, color: UIColor.yellowColor())
        arc1.frame = viewFrame
        arc2.frame = viewFrame
        arc3.frame = viewFrame
        layer.addSublayer(arc1)
        layer.addSublayer(arc2)
        layer.addSublayer(arc3)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public static func createEmptyLoaderInView(view: UIView, size: CGFloat = size) -> TwicketLoader {
        let loader = TwicketLoader(empty: true, size: size)
        loader.centerInView(view)
        view.addSubview(loader)
        return loader
    }
    
    public static func createLoaderInView(view: UIView, size: CGFloat = size) -> TwicketLoader {
        let loader = TwicketLoader(size: size)
        loader.hidden = true
        loader.alpha = 0.0
        loader.centerInView(view)
        view.addSubview(loader)
        return loader
    }
    
    public func showLoader(animated: Bool = true) {
        if animate { return }
        animate = true
        let animations = { self.alpha = 1.0 }
        if animated {
            UIView.animateWithDuration(0.5, animations: animations)
        }
        else {
            animations()
        }
        hidden = false
        rotateArc1()
        rotateArc2()
        rotateArc3()
    }
    
    public func hideLoader(animated: Bool = true, completion: (() -> ())? = nil) {
        let animations = { self.alpha = 0.0 }
        let removeLoader: (Bool) -> () = { completed in
            self.hidden = true
            self.cancelAnimations()
            completion?()
        }
        
        if !animated {
            animations()
            removeLoader(true)
            return
        }
        UIView.animateWithDuration(0.5, animations: animations, completion: removeLoader)
    }
    
    public func removeLoader(animated: Bool = true) {
        hideLoader(animated) {
            self.removeFromSuperview()
        }
    }
    
    public func advanceToProgress(progress: CGFloat) {
        let maxValue = CGFloat(2*M_PI)
        let angleWidth = maxValue*progress
        if angleWidth > maxValue { return }
        UIView.animateWithDuration(0.5) {
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
    
    private func rotate(shape: CAShapeLayer, withDuration duration: NSTimeInterval, animation: AnimationKeys) {
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
        shape.addAnimation(rotate, forKey: "rotation")
    }
    
    private func randomAngle() -> CGFloat {
        return randomBetweenNumbers(CGFloat(M_PI_2), secondNum: CGFloat(M_PI_2)/3)
    }
    
    private func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    
    //MARK: Animation delegate
    
    override public func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        guard let identifier = anim.valueForKey("identifier") as? String
            where animate else { return }
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
    
    private static func arcLayer(radius radius: CGFloat, angleWidth: CGFloat, center: CGPoint, lineWidth: CGFloat, color: UIColor) -> CAShapeLayer {
        let progressRingLayer = CAShapeLayer()
        progressRingLayer.path = arcPath(radius: radius, angleWidth: angleWidth, center: center)
        progressRingLayer.lineWidth = lineWidth
        progressRingLayer.strokeColor = color.CGColor
        progressRingLayer.lineCap = kCALineCapRound
        progressRingLayer.fillColor = UIColor.clearColor().CGColor
        return progressRingLayer
    }
    
    private static func arcPath(radius radius: CGFloat, angleWidth: CGFloat, center: CGPoint, inverse: Bool = false) -> CGPath {
        let initialAngle = CGFloat(-M_PI_2)
        return UIBezierPath(arcCenter: center,
            radius: radius,
            startAngle: initialAngle,
            endAngle: inverse ? -angleWidth + initialAngle : angleWidth + initialAngle,
            clockwise: !inverse).CGPath
    }

}
