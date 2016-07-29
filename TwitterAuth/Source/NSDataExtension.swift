//
//  NSDataExtension.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

extension Data {
    func toString() -> String? {
        guard let signedAuthSignature = String(data: self, encoding: String.Encoding.utf8) else {
            return nil
        }
        return signedAuthSignature
    }
}
