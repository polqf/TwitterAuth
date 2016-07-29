//
//  ReverseAuthResult.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

private let oauthTokenKey = "oauth_token="
private let oauthTokenSecretKey = "oauth_token_secret="
private let userIDKey = "user_id="
private let userNameKey = "screen_name="

enum CredentialsIndex: Int {
    case oAuthToken
    case oAuthTokenSecret
    case userID
    case userName
}

public struct TwitterAuthResult {
    public let oauthToken: String
    public let oauthTokenSecret: String
    public let userID: String
    public let userName: String
    
    public init?(stringResponse: String) {
        let components = TwitterAuthResult.parse(stringResponse)
        guard components.count == 4 else { return nil }
        oauthToken = components[CredentialsIndex.oAuthToken.rawValue]
        oauthTokenSecret = components[CredentialsIndex.oAuthTokenSecret.rawValue]
        userID = components[CredentialsIndex.userID.rawValue]
        userName = components[CredentialsIndex.userName.rawValue]
    }
    
    static func parse(_ string: String) -> [String]{
        return string.components(separatedBy: "&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.range(of: oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.range(of: oauthTokenSecretKey) {
                    stringRange = range
                }
                else if let range = string.range(of: userIDKey) {
                    stringRange = range
                }
                else if let range = string.range(of: userNameKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substring(from: range.upperBound)
        }
    }
}
