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
    case oAuthToken
    case oAuthTokenSecret
    case oAuthCallbackConfirmed
}

struct RequestTokenResult {
    let oauthToken: String
    let oauthTokenSecret: String
    let oauthCallbackConfirmed: Bool
    
    init?(stringResponse: String) {
        let components = RequestTokenResult.parse(stringResponse)
        guard components.count == 3 else { return nil }
        oauthToken = components[RequestTokenCredentialsIndex.oAuthToken.rawValue]
        oauthTokenSecret = components[RequestTokenCredentialsIndex.oAuthTokenSecret.rawValue]
        oauthCallbackConfirmed = components[RequestTokenCredentialsIndex.oAuthCallbackConfirmed.rawValue] == "true"
    }
    
    static func parse(_ string: String) -> [String] {
        return string
            .components(separatedBy: "&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.range(of: oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.range(of: oauthTokenSecretKey) {
                    stringRange = range
                }
                else if let range = string.range(of: oauthCallbackConfirmedKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substring(from: range.upperBound)
        }
    }
}

enum RedirectionCredentialsIndex: Int {
    case oAuthToken
    case oAuthVerifier
}

//  twicket://auth?oauth_token=OHPgMwAAAAAAhXpOAAABUyfsPyU&oauth_verifier=3xeRKfvThr9X1VdLcN2cDke0ChFHD4o4

struct RedirectionResult {
    let oauthToken: String
    let oauthVerifier: String
    
    init?(stringResponse: String) {
        let components = RedirectionResult.parse(stringResponse)
        guard components.count == 2 else { return nil }
        oauthToken = components[RedirectionCredentialsIndex.oAuthToken.rawValue]
        oauthVerifier = components[RedirectionCredentialsIndex.oAuthVerifier.rawValue]
    }
    
    static func parse(_ string: String) -> [String] {
        return string
            .components(separatedBy: "&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.range(of: oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.range(of: oauthVerifierKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substring(from: range.upperBound)
        }
    }
}

enum AccessTokenCredentialsIndex: Int {
    case oAuthToken
    case oAuthTokenSecret
}

//oauth_token=7588892-kagSNqWge8gB1WwE3plnFsJHAZVfxWD7Vb57p0b4&oauth_token_secret=PbKfYqSryyeKDWz4ebtY3o5ogNLG11WJuZBc9fQrQo

struct AccessTokenResult {
    let oauthToken: String
    let oauthTokenSecret: String
    
    init?(stringResponse: String) {
        let components = AccessTokenResult.parse(stringResponse)
        guard components.count == 2 else { return nil }
        oauthToken = components[AccessTokenCredentialsIndex.oAuthToken.rawValue]
        oauthTokenSecret = components[AccessTokenCredentialsIndex.oAuthTokenSecret.rawValue]
    }
    
    static func parse(_ string: String) -> [String] {
        return string
            .components(separatedBy: "&")
            .flatMap { string -> String? in
                var stringRange: Range<String.Index>?
                if let range = string.range(of: oauthTokenKey) {
                    stringRange = range
                }
                else if let range = string.range(of: oauthTokenSecretKey) {
                    stringRange = range
                }
                guard let range = stringRange else { return nil }
                return string.substring(from: range.upperBound)
        }
    }
}
