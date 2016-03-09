//
//  Threading.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

struct Threading {
    static func executeOnMainThread(block: Void -> Void) {
        if NSThread.isMainThread() {
            return block()
        }
        dispatch_async(dispatch_get_main_queue(), block)
    }
}
