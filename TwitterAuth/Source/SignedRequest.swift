//
//  SignedRequest.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation

public enum MethodType: String {
    case GET
    case POST
    case DELETE
}

private let timeoutInterval: NSTimeInterval = 8
private let authorizationHeaderKey = "Authorization"

public struct SignedRequest {
    let url: NSURL
    let parameters: [String : AnyObject]
    let method: MethodType
    let consumerKey: String
    let consumerSecret: String
    let oauthToken: String?
    let oauthCallback: String?
    
    public var urlRequest: NSURLRequest? {
        return buildRequest()
    }
    
    public init(url: NSURL,
        parameters: [String : AnyObject] = [:],
        method: MethodType,
        consumerKey: String,
        consumerSecret: String,
        oauthToken: String? = nil,
        oauthCallback: String? = nil) {
            self.url = url
            self.parameters = parameters
            self.method = method
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.oauthCallback = oauthCallback
            self.oauthToken = oauthToken
    }
    
    
    //MARK: Private
    
    private func buildRequest() -> NSURLRequest? {
        guard let bodyData = buildBodyData() else { return nil }
        let authorizationHeader = OAuthorizationHeaderWithCallback(url, method.rawValue, bodyData, consumerKey, consumerSecret, oauthToken, nil, oauthCallback)
        let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: timeoutInterval)
        request.HTTPMethod = method.rawValue
        request.setValue(authorizationHeader, forHTTPHeaderField: authorizationHeaderKey)
        request.HTTPBody = bodyData
        return request
    }
    
    private func buildBodyData() -> NSData? {
        let string: String = parameters.reduce("") { (initial, dict) -> String in
            guard let value = dict.1 as? String else { return initial }
            return initial + "\(dict.0)=\(value)&"
        }
        return string.dataUsingEncoding(NSUTF8StringEncoding)
    }
}
