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
    case OAuthToken
    case OAuthTokenSecret
    case UserID
    case UserName
}

public struct TwitterAuthResult {
    public let oauthToken: String
    public let oauthTokenSecret: String
    public let userID: String
    public let userName: String
    
    public init?(stringResponse: String) {
        let components = TwitterAuthResult.parseString(stringResponse)
        guard components.count == 4 else { return nil }
        oauthToken = components[CredentialsIndex.OAuthToken.rawValue]
        oauthTokenSecret = components[CredentialsIndex.OAuthTokenSecret.rawValue]
        userID = components[CredentialsIndex.UserID.rawValue]
        userName = components[CredentialsIndex.UserName.rawValue]
    }
    
    static func parseString(string: String) -> [String]{
        return string.componentsSeparatedByString("&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.rangeOfString(oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(oauthTokenSecretKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(userIDKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(userNameKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substringFromIndex(range.endIndex)
        }
    }
}
