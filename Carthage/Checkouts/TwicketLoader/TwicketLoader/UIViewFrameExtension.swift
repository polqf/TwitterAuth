//
//  UIViewControllerNavButtonsExtension.swift
//  Twicket
//
//  Created by Pol Quintana on 07/09/15.
//  Copyright © 2015 Pol Quintana. All rights reserved.
//

import UIKit

extension UIView {
    var frameSize: CGSize {
        get {
            return frame.size
        }
        set {
            frame = CGRect(x: frameLeft, y: frameTop, width: newValue.width, height: newValue.height)
        }
    }
    var frameWidth: CGFloat {
        get {
            return frame.size.width
        }
        set {
            frame = CGRect(x: frameLeft, y: frameTop, width: newValue, height: frameHeight)
        }
    }
    var frameHeight: CGFloat {
        get {
            return frame.size.height
        }
        set {
            frame = CGRect(x: frameLeft, y: frameTop, width: frameWidth, height: newValue)
        }
    }
    var frameOrigin: CGPoint {
        get {
            return frame.origin
        }
        set {
            frame = CGRect(x: newValue.x, y: newValue.y, width: frameWidth, height: frameHeight)
        }
    }
    var frameBottom: CGFloat {
        get {
            return frameTop + frameHeight
        }
        set {
            frame = CGRect(x: frameLeft, y: newValue - frameHeight, width: frameWidth, height: frameHeight)
        }
    }
    var frameTop: CGFloat {
        get {
            return frame.origin.y
        }
        set {
            frame = CGRect(x: frameLeft, y: newValue, width: frameWidth, height: frameHeight)
        }
    }
    var frameRight: CGFloat {
        get {
            return frameLeft + frameWidth
        }
        set {
            frame = CGRect(x: newValue - frameWidth, y: frameTop, width: frameWidth, height: frameHeight)
        }
    }
    var frameLeft: CGFloat {
        get {
            return frame.origin.x
        }
        set {
            frame = CGRect(x: newValue, y: frameTop, width: frameWidth, height: frameHeight)
        }
    }
    
    //CENTER
    var centerX: CGFloat {
        get {
            return center.x
        }
        set {
            center = CGPoint(x: newValue, y: center.y)
        }
    }
    var centerY: CGFloat {
        get {
            return center.y
        }
        set {
            center = CGPoint(x: center.x, y: newValue)
        }
    }
    
    func center(in view: UIView) {
        centerX = view.frameWidth/2
        centerY = view.frameHeight/2
    }
}
