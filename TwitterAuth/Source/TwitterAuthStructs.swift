//
//  TwitterAuthStructs.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 09/03/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

private let oauthTokenKey = "oauth_token="
private let oauthTokenSecretKey = "oauth_token_secret="
private let oauthCallbackConfirmedKey = "oauth_callback_confirmed="
private let oauthVerifierKey = "oauth_verifier="

enum RequestTokenCredentialsIndex: Int {
    case OAuthToken
    case OAuthTokenSecret
    case OAuthCallbackConfirmed
}

struct RequestTokenResult {
    let oauthToken: String
    let oauthTokenSecret: String
    let oauthCallbackConfirmed: Bool
    
    init?(stringResponse: String) {
        let components = RequestTokenResult.parseString(stringResponse)
        guard components.count == 3 else { return nil }
        oauthToken = components[RequestTokenCredentialsIndex.OAuthToken.rawValue]
        oauthTokenSecret = components[RequestTokenCredentialsIndex.OAuthTokenSecret.rawValue]
        oauthCallbackConfirmed = components[RequestTokenCredentialsIndex.OAuthCallbackConfirmed.rawValue] == "true"
    }
    
    static func parseString(string: String) -> [String] {
        return string
            .componentsSeparatedByString("&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.rangeOfString(oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(oauthTokenSecretKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(oauthCallbackConfirmedKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substringFromIndex(range.endIndex)
        }
    }
}

enum RedirectionCredentialsIndex: Int {
    case OAuthToken
    case OAuthVerifier
}

//  twicket://auth?oauth_token=OHPgMwAAAAAAhXpOAAABUyfsPyU&oauth_verifier=3xeRKfvThr9X1VdLcN2cDke0ChFHD4o4

struct RedirectionResult {
    let oauthToken: String
    let oauthVerifier: String
    
    init?(stringResponse: String) {
        let components = RedirectionResult.parseString(stringResponse)
        guard components.count == 2 else { return nil }
        oauthToken = components[RedirectionCredentialsIndex.OAuthToken.rawValue]
        oauthVerifier = components[RedirectionCredentialsIndex.OAuthVerifier.rawValue]
    }
    
    static func parseString(string: String) -> [String] {
        return string
            .componentsSeparatedByString("&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.rangeOfString(oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(oauthVerifierKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substringFromIndex(range.endIndex)
        }
    }
}

enum AccessTokenCredentialsIndex: Int {
    case OAuthToken
    case OAuthTokenSecret
}

//oauth_token=7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4&oauth_token_secret=PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo

struct AccessTokenResult {
    let oauthToken: String
    let oauthTokenSecret: String
    
    init?(stringResponse: String) {
        let components = AccessTokenResult.parseString(stringResponse)
        guard components.count == 2 else { return nil }
        oauthToken = components[AccessTokenCredentialsIndex.OAuthToken.rawValue]
        oauthTokenSecret = components[AccessTokenCredentialsIndex.OAuthTokenSecret.rawValue]
    }
    
    static func parseString(string: String) -> [String] {
        return string
            .componentsSeparatedByString("&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.rangeOfString(oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.rangeOfString(oauthTokenSecretKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substringFromIndex(range.endIndex)
        }
    }
}
