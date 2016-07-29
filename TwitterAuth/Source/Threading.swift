//
//  Threading.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

struct Threading {
    static func executeOnMainThread(_ block: (Void) -> Void) {
        if Thread.isMainThread {
            return block()
        }
        DispatchQueue.main.async(execute: block)
    }
}
