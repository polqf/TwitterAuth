//
//  WebManager.swift
//  TwitterAuthDemo
//
//  Created by Pol Quintana on 08/03/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import UIKit
import Accounts
import SafariServices

class TwicketWebManager: NSObject {
    
    private var safariViewController: SFSafariViewController?
    private var lastOAuthToken: String?
    
    var consumerKey: String = ""
    var consumerSecret: String = ""
    var callbackStringURL: String = ""

    func openLogin(onViewController viewController: UIViewController, token: String) {
        _checkNecessaryProperties()
        lastOAuthToken = token
        let url = NSURL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=\(token)")!
        let safariVC = SFSafariViewController(URL: url)
        safariVC.delegate = self
        self.safariViewController = safariVC
        viewController.navigationController?.presentViewController(safariVC, animated: true, completion: nil)
    }
    
    func processAuthCallback(callbackURL: NSURL, completion: TwitterAuthCompletion) {
        _checkNecessaryProperties()
        let callback = callbackURL.absoluteString
        guard callback.containsString(callbackStringURL),
            let result = RedirectionResult(stringResponse: callback) where result.oauthToken == lastOAuthToken else {
                //TODO: DO SOMETHING
                return
        }
        
        print("🙆 VERIFIER: \(result.oauthVerifier)")
        let request = twitterRequest2(token: result.oauthToken, verifier: result.oauthVerifier)
        obtainAccessToken(request, completion: completion)
    }
    
    
    //MARK: API Requests
    
    private func obtainRequestToken(completion: (token: String?, error: TwitterAuthError?) -> ()) {
        let request = twitterRequest()
        performRequest(request, mapper: RequestTokenResult.init) { (element, error) in
            guard let element = element else {
                return completion(token: nil, error: error)
            }
            self.lastOAuthToken = element.oauthToken
            completion(token: element.oauthToken, error: nil)
        }
    }
    
    private func obtainAccessToken(request: NSURLRequest, completion: TwitterAuthCompletion) {
        performRequest(request, mapper: TwitterAuthResult.init) { (element, error) in
            guard let element = element else {
                return completion(result: nil, error: error)
            }
            completion(result: element, error: nil)
        }
        
    }
    
    private func performRequest<T>(request: NSURLRequest, mapper: (String -> T?), completion: (element: T?, error: TwitterAuthError?) -> ()) {
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard let data = data, string = String(data: data, encoding: NSUTF8StringEncoding) else {
                return completion(element: nil, error: nil) //SOME ERROR HERE!!!!!
            }
            let result = mapper(string)
            completion(element: result, error: nil)
        }
        task.resume()
    }
    
    
    //MARK: Requests
    
    func twitterRequest() -> NSURLRequest {
        return SignedRequest(url: NSURL(string: "https://api.twitter.com/oauth/request_token")!,
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            oauthCallback: callbackStringURL)
            .urlRequest! //TODO: WTF
    }
    
    func twitterRequest2(token token: String, verifier: String) -> NSURLRequest {
        return SignedRequest(url: NSURL(string: "https://api.twitter.com/oauth/access_token")!,
            parameters: ["oauth_verifier" : verifier],
            method: .POST,
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            oauthToken: token)
            .urlRequest! //TODO: WTF
    }
    
    private func _checkNecessaryProperties() {
        if consumerKey.isEmpty || consumerSecret.isEmpty || callbackStringURL.isEmpty {
            fatalError("You must call configure(consumerKey:consumerSecret:callback:) on TwitterAuth.sharedInstance before calling any other methods")
        }
    }
}

extension TwicketWebManager: SFSafariViewControllerDelegate {
    
    /*! @abstract Called when the view controller is about to show UIActivityViewController after the user taps the action button.
    @param URL, the URL of the web page.
    @param title, the title of the web page.
    @result Returns an array of UIActivity instances that will be appended to UIActivityViewController.
    */
    public func safariViewController(controller: SFSafariViewController, activityItemsForURL URL: NSURL, title: String?) -> [UIActivity] {
        return []
    }
    
    /*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the view controller is dismissed modally. */
    public func safariViewControllerDidFinish(controller: SFSafariViewController) {
        
    }
    
    /*! @abstract Invoked when the initial URL load is complete.
    @param success YES if loading completed successfully, NO if loading failed.
    @discussion This method is invoked when SFSafariViewController completes the loading of the URL that you pass
    to its initializer. It is not invoked for any subsequent page loads in the same SFSafariViewController instance.
    */
    public func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if !didLoadSuccessfully {
            
        }
        print("DID LOAD SUCCESSFULLY: \(didLoadSuccessfully)")
    }
}

private let oauthTokenKey = "oauth_token="
private let oauthTokenSecretKey = "oauth_token_secret="
private let oauthCallbackConfirmedKey = "oauth_callback_confirmed="
private let oauthVerifierKey = "oauth_verifier="

enum RequestTokenCredentialsIndex: Int {
    case OAuthToken
    case OAuthTokenSecret
    case OAuthCallbackConfirmed
}

public struct RequestTokenResult {
    public let oauthToken: String
    public let oauthTokenSecret: String
    public let oauthCallbackConfirmed: Bool
    
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

public struct RedirectionResult {
    public let oauthToken: String
    public let oauthVerifier: String
    
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

public struct AccessTokenResult {
    public let oauthToken: String
    public let oauthTokenSecret: String
    
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

