//
//  Threading.swift
//  TwitterReverseOAuth
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
    
    static func executeOnBackgroundThread(block: Void -> Void) {
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue, block)
    }
}
