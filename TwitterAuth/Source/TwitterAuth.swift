//
//  ReverseOAuth.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 30/01/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import Foundation
import Accounts
import UIKit
import TwicketLoader

public typealias TwitterAuthCompletion = (result: TwitterAuthResult?, error: TwitterAuthError?) -> ()
public typealias TwitterAuthErrorCompletion = (error: TwitterAuthError?) -> ()

public enum TwitterAuthError: ErrorType {
    case ErrorGettingHeader
    case ErrorGettingTokens
    case BadURLRequest
    case NoAccessToAccounts
    case NoAvailableAccounts
    case WrongCallback
    case UnableToLoadWeb
    case UnableToSaveAccount
    case UserCancelled
    case Unknown
}

public protocol TwitterAuthWebLoginDelegate: class {
    func didSuccedRetrivingToken(result: TwitterAuthResult)
    func didFailRetrievingToken(error: TwitterAuthError)
}

public class TwitterAuth {
    
    public static let sharedInstance = TwitterAuth()
    public weak var webLoginDelegate: TwitterAuthWebLoginDelegate?
    public var saveInACAccounts: Bool = false
    
    private var apiManager: APIManager = APIManager()
    private let webManager: TwicketWebManager = TwicketWebManager()
    private let accountStore = ACAccountStore()
    
    private var callbackStringURL: String = ""
    private var lastOAuthToken: String?
    
    public func configure(withConsumerKey consumerKey: String, consumerSecret: String, callbackURL: String) {
        self.apiManager.consumerKey = consumerKey
        self.apiManager.consumerSecret = consumerSecret
        self.webManager.consumerSecret = consumerKey
        self.webManager.consumerKey = consumerSecret
        self.callbackStringURL = callbackURL
    }
    
    public func executeReverseOAuth(forAccount account: ACAccount, completion: TwitterAuthCompletion) {
        apiManager.executeReverseAuth(forAccount: account) { result, error in
            Threading.executeOnMainThread { completion(result: result, error: error) }
        }
    }
    
    public func executeReverseOAuthWithAvailableAccounts(onViewController vc: UIViewController,
        completion: TwitterAuthCompletion) {
            getTwitterAccounts { accounts, error in
                guard let accounts = accounts else {
                    return Threading.executeOnMainThread { completion(result: nil, error: error ?? .NoAccessToAccounts) }
                }
                self.showAccountsAlertView(onViewController: vc, withAccounts: accounts) { selectedAccount in
                    self.executeReverseOAuth(forAccount: selectedAccount, completion: completion)
                }
            }
    }
    
    public func presentWebLogin(fromViewController viewController: UIViewController) {
        let loader = TwicketLoader.createLoaderInView(viewController.view)
        loader.showLoader()
        apiManager.obtainRequestToken(callbackStringURL) { token, error in
            Threading.executeOnMainThread {
                loader.removeLoader()
                guard let token = token else {
                    self.notifyWebLoginError(error ?? .Unknown)
                    return
                }
                self.lastOAuthToken = token
                self.webManager.openLogin(onViewController: viewController, token: token)
            }
        }
    }
    
    public func processAuthCallback(callback: NSURL) {
        let callback = callback.absoluteString
        guard !callbackStringURL.isEmpty &&
            callback.containsString(self.callbackStringURL),
            let result = RedirectionResult(stringResponse: callback)
            where result.oauthToken == self.lastOAuthToken else {
                self.notifyWebLoginError(.WrongCallback)
                return
        }
        
        apiManager.obtainAccessToken(withResult: result) { (result, error) -> () in
                guard let result = result else {
                    self.notifyWebLoginError(error ?? .Unknown)
                    return
                }
                if self.saveInACAccounts {
                    self.saveAccount(withResult: result) { succeed in
                        succeed ? self.notifyWebLoginSuccess(result) : self.notifyWebLoginError(.UnableToSaveAccount)
                    }
                    return
                }
                self.notifyWebLoginSuccess(result)
        }
    }
    
    
    //MARK: Private methods
    
    private func notifyWebLoginSuccess(result: TwitterAuthResult) {
        Threading.executeOnMainThread {
            self.webLoginDelegate?.didSuccedRetrivingToken(result)
            self.hideSafariViewController()
        }
    }
    
    private func notifyWebLoginError(error: TwitterAuthError) {
        Threading.executeOnMainThread {
            self.webLoginDelegate?.didFailRetrievingToken(error ?? .Unknown)
            self.hideSafariViewController()
        }
    }
    
    private func hideSafariViewController() {
        self.lastOAuthToken = nil
        self.webManager.clearSafariViewController()
    }
    
    
    //MARK: ACAccount
    
    private func saveAccount(withResult result: TwitterAuthResult, completion: (Bool) -> ()) {
        let credential = ACAccountCredential(OAuthToken: result.oauthToken, tokenSecret: result.oauthTokenSecret)
        let type = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        let account = ACAccount(accountType: type)
        account.credential = credential
        
        accountStore.saveAccount(account) { (succeed, error) in
            completion(succeed)
            if !succeed {
                NSLog("[TwitterAuth] ERROR saving new account to ACAccount:\n\(error.localizedDescription)")
            }
        }
    }
    
    private func getTwitterAccounts(completion: (accounts: [ACAccount]?, error: TwitterAuthError?) -> ()) {
        let type = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(type, options: nil) { succeed, error in
            guard succeed else {
                return completion(accounts: nil, error: .NoAccessToAccounts)
            }
            guard let accounts = self.accountStore.accountsWithAccountType(type) as? [ACAccount]
                where !accounts.isEmpty else {
                    return completion(accounts: nil, error: .NoAvailableAccounts)
            }
            completion(accounts: accounts, error: nil)
        }
    }
    
    private func showAccountsAlertView(onViewController vc: UIViewController,
        withAccounts accounts: [ACAccount],
        selectedAccountBlock: (selectedAccount: ACAccount) -> ()) {
            let alert = UIAlertController(title: "Available Accounts",
                message: "(Twitter)",
                preferredStyle: .ActionSheet)
            accounts.forEach { account in
                let action = UIAlertAction(title: account.username,
                    style: .Default) { (action) in
                        selectedAccountBlock(selectedAccount: account)
                }
                alert.addAction(action)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { _ in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(cancel)
            
            Threading.executeOnMainThread {
                vc.presentViewController(alert, animated: true, completion: nil)
            }
    }
}

