//
//  NSDataExtension.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

extension NSData {
    func toString() -> String? {
        guard let signedAuthSignature = String(data: self, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        return signedAuthSignature
    }
}