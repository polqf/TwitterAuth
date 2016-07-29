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
                return completion(result: nil, error: error)
            }
            
            self.getTokens(for: account, signature: signedAuthSignature) { (data, error) in
                guard let stringResponse = data?.toString() else {
                    return completion(result: nil, error: error)
                }
                let result = TwitterAuthResult(stringResponse: stringResponse)
                completion(result: result, error: error)
            }
        }
    }
    
    func obtainRequestToken(callback: String, completion: (token: String?, error: TwitterAuthError?) -> ()) {
        _checkNecessaryProperties()
        let request = createRequestTokenRequest(with: callback)
        perform(request, mapper: RequestTokenResult.init) { (element, error) in
            guard let element = element, element.oauthCallbackConfirmed else {
                return completion(token: nil, error: error)
            }
            completion(token: element.oauthToken, error: nil)
        }
    }
    
    func obtainAccessToken(withResult result: RedirectionResult, completion: TwitterAuthCompletion) {
        _checkNecessaryProperties()
        let request = createAccessTokenRequest(token: result.oauthToken, verifier: result.oauthVerifier)
        perform(request, mapper: TwitterAuthResult.init) { (element, error) in
            guard let element = element else {
                return completion(result: nil, error: error)
            }
            completion(result: element, error: nil)
        }
        
    }
    
    
    //MARK: Private methods
    
    private func obtainAuthorizationHeader(completion: (signature: String?, error: TwitterAuthError?) -> ()) {
        guard let url = URL(string: requestTokenURL) else {
            return completion(signature: nil, error: .badURLRequest)
        }
        let params: [String : AnyObject] = [authModeKey : reverseAuthMode]
        let request = SignedRequest(url: url,
            parameters: params,
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret)
        guard let urlRequest = request.urlRequest else {
            return completion(signature: nil, error: .badURLRequest)
        }
        
        perform(urlRequest, mapper: { $0 }) { (element, error) -> () in
            completion(signature: element, error: error != nil ? .errorGettingHeader : nil)
        }
    }
    
    private func getTokens(for account: ACAccount,
        signature: String,
        completion: (data: Data?, error: TwitterAuthError?) -> ()) {
            guard let url = URL(string: accessTokenURL) else {
                return completion(data: nil, error: .badURLRequest)
            }
            let params: [String : AnyObject] = [
                reverseAuthTarget : consumerKey,
                reverseAuthParams : signature
            ]
            
            let slrequest = request(with: url, parameters: params, requestMethod: .POST)
            slrequest.account = account
            slrequest.perform { (data, response, error) in
                if let _ = error {
                    return completion(data: nil, error: .errorGettingTokens)
                }
                completion(data: data, error: nil)
            }
    }
    
    private func perform<T>(_ request: URLRequest,
        mapper: ((String) -> T?),
        completion: (element: T?, error: TwitterAuthError?) -> ()) {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data, let string = String(data: data, encoding: String.Encoding.utf8) else {
                    return completion(element: nil, error: .badURLRequest)
                }
                let result = mapper(string)
                completion(element: result, error: nil)
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
            parameters: [oauthVerifierKey : verifier],
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
