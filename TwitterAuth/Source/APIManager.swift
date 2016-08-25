//
//  APIManager.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 24/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation
import Social
import Accounts

private let baseURL = "https://api.twitter.com"
private let authModeKey = "x_auth_mode"
private let reverseAuthMode = "reverse_auth"
private let clientAuthMode = "client_auth"
private let oauthVerifierKey = "oauth_verifier"
private let reverseAuthParams = "x_reverse_auth_parameters"
private let reverseAuthTarget = "x_reverse_auth_target"
private let requestTokenURL = baseURL + "/oauth/request_token"
private let accessTokenURL = baseURL + "/oauth/access_token"

struct APIManager {
    
    private static let apiQueue = OperationQueue()
    var consumerKey: String = ""
    var consumerSecret: String = ""
    
    func executeReverseAuth(forAccount account: ACAccount, completion: TwitterAuthCompletion) {
        _checkNecessaryProperties()
        obtainAuthorizationHeader { (signature, error) in
            guard let signedAuthSignature = signature else {
                return completion(nil, error)
            }
            
            self.getTokens(for: account, signature: signedAuthSignature) { (data, error) in
                guard let stringResponse = data?.toString() else {
                    return completion(nil, error)
                }
                let result = TwitterAuthResult(stringResponse: stringResponse)
                completion(result, error)
            }
        }
    }
    
    func obtainRequestToken(callback: String, completion: @escaping (_ token: String?, _ error: TwitterAuthError?) -> ()) {
        _checkNecessaryProperties()
        let request = createRequestTokenRequest(with: callback)
        perform(request, mapper: RequestTokenResult.init) { (element, error) in
            guard let element = element, element.oauthCallbackConfirmed else {
                return completion(nil, error)
            }
            completion(element.oauthToken, nil)
        }
    }
    
    func obtainAccessToken(withResult result: RedirectionResult, completion: TwitterAuthCompletion) {
        _checkNecessaryProperties()
        let request = createAccessTokenRequest(token: result.oauthToken, verifier: result.oauthVerifier)
        perform(request, mapper: TwitterAuthResult.init) { (element, error) in
            guard let element = element else {
                return completion(nil, error)
            }
            completion(element, nil)
        }
        
    }
    
    
    //MARK: Private methods
    
    private func obtainAuthorizationHeader(completion: @escaping (_ signature: String?, _ error: TwitterAuthError?) -> ()) {
        guard let url = URL(string: requestTokenURL) else {
            return completion(nil, .badURLRequest)
        }
        let params: [String : AnyObject] = [authModeKey : reverseAuthMode as AnyObject]
        let request = SignedRequest(url: url,
            parameters: params,
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret)
        guard let urlRequest = request.urlRequest else {
            return completion(nil, .badURLRequest)
        }
        
        perform(urlRequest, mapper: String.init) { (element, error) -> () in
            completion(element, error != nil ? .errorGettingHeader : nil)
        }
    }
    
    private func getTokens(for account: ACAccount,
        signature: String,
        completion: @escaping (_ data: Data?, _ error: TwitterAuthError?) -> ()) {
            guard let url = URL(string: accessTokenURL) else {
                return completion(nil, .badURLRequest)
            }
            let params: [String : AnyObject] = [
                reverseAuthTarget : consumerKey as AnyObject,
                reverseAuthParams : signature as AnyObject
            ]
            
            let slrequest = request(with: url, parameters: params, requestMethod: .POST)
            slrequest.account = account
            slrequest.perform { (data, response, error) in
                if let _ = error {
                    return completion(nil, .errorGettingTokens)
                }
                completion(data, nil)
            }
    }
    
    private func perform<T>(_ request: URLRequest,
        mapper: ((String) -> T?),
        completion: @escaping (_ element: T?, _ error: TwitterAuthError?) -> ()) {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data, let string = String(data: data, encoding: String.Encoding.utf8) else {
                    return completion(nil, .badURLRequest)
                }
                let result = mapper(string)
                completion(result, nil)
            }
            task.resume()
    }
    
    private func request(with url: URL, parameters: [String : AnyObject], requestMethod: SLRequestMethod) -> SLRequest {
        return SLRequest(forServiceType: SLServiceTypeTwitter,
            requestMethod: requestMethod,
            url: url,
            parameters: parameters)
    }
    
    
    //MARK: Requests
    
    private func createRequestTokenRequest(with callback: String) -> URLRequest {
        return SignedRequest(url: URL(string: requestTokenURL)!,
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            oauthCallback: callback)
            .urlRequest! as URLRequest
    }
    
    private func createAccessTokenRequest(token: String, verifier: String) -> URLRequest {
        return SignedRequest(url: URL(string: accessTokenURL)!,
            parameters: [oauthVerifierKey : verifier as AnyObject],
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            oauthToken: token)
            .urlRequest!
    }
    
    private func _checkNecessaryProperties() {
        if consumerKey.isEmpty || consumerSecret.isEmpty {
            fatalError("You must call configure(consumerKey:consumerSecret:callback:) on TwitterAuth.sharedInstance before calling any other methods")
        }
    }
}
