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

public typealias TwitterAuthCompletion = (_ result: TwitterAuthResult?, _ error: TwitterAuthError?) -> ()
public typealias TwitterAuthErrorCompletion = (_ error: TwitterAuthError?) -> ()

public enum TwitterAuthError: Error {
    case errorGettingHeader
    case errorGettingTokens
    case badURLRequest
    case noAccessToAccounts
    case noAvailableAccounts
    case wrongCallback
    case unableToLoadWeb
    case unableToSaveAccount
    case userCancelled
    case unknown
}

public protocol TwitterAuthWebLoginDelegate: class {
    func didSuccedRetrivingToken(_ result: TwitterAuthResult)
    func didFailRetrievingToken(_ error: TwitterAuthError)
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
    
    public func executeReverseOAuth(forAccount account: ACAccount, completion: @escaping TwitterAuthCompletion) {
        apiManager.executeReverseAuth(forAccount: account) { result, error in
            Threading.executeOnMainThread { completion(result, error) }
        }
    }
    
    public func executeReverseOAuthWithAvailableAccounts(onViewController vc: UIViewController,
        completion: @escaping TwitterAuthCompletion) {
            getTwitterAccounts { accounts, error in
                guard let accounts = accounts else {
                    return Threading.executeOnMainThread { completion(nil, error ?? .noAccessToAccounts) }
                }
                self.showAccountsAlertView(onViewController: vc, withAccounts: accounts) { selectedAccount in
                    self.executeReverseOAuth(forAccount: selectedAccount, completion: completion)
                }
            }
    }
    
    public func presentWebLogin(fromViewController viewController: UIViewController) {
        apiManager.obtainRequestToken(callback: callbackStringURL) { token, error in
            Threading.executeOnMainThread {
                guard let token = token else {
                    self.notifyWebLoginError(error ?? .unknown)
                    return
                }
                self.lastOAuthToken = token
                self.webManager.openLogin(onViewController: viewController, token: token)
            }
        }
    }
    
    public func processAuthCallback(_ callback: URL) {
        let callback = callback.absoluteString
        guard !callbackStringURL.isEmpty &&
            (callback.contains(self.callbackStringURL)),
            let result = RedirectionResult(stringResponse: callback), result.oauthToken == self.lastOAuthToken else {
                self.notifyWebLoginError(.wrongCallback)
                return
        }
        
        apiManager.obtainAccessToken(withResult: result) { (result, error) -> () in
                guard let result = result else {
                    self.notifyWebLoginError(error ?? .unknown)
                    return
                }
                if self.saveInACAccounts {
                    self.saveAccount(withResult: result) { succeed in
                        succeed ? self.notifyWebLoginSuccess(result) : self.notifyWebLoginError(.unableToSaveAccount)
                    }
                    return
                }
                self.notifyWebLoginSuccess(result)
        }
    }
    
    
    //MARK: Private methods
    
    private func notifyWebLoginSuccess(_ result: TwitterAuthResult) {
        Threading.executeOnMainThread {
            self.webLoginDelegate?.didSuccedRetrivingToken(result)
            self.hideSafariViewController()
        }
    }
    
    private func notifyWebLoginError(_ error: TwitterAuthError) {
        Threading.executeOnMainThread {
            self.webLoginDelegate?.didFailRetrievingToken(error)
            self.hideSafariViewController()
        }
    }
    
    private func hideSafariViewController() {
        self.lastOAuthToken = nil
        self.webManager.clearSafariViewController()
    }
    
    
    //MARK: ACAccount
    
    private func saveAccount(withResult result: TwitterAuthResult, completion: @escaping (Bool) -> ()) {
        let credential = ACAccountCredential(oAuthToken: result.oauthToken, tokenSecret: result.oauthTokenSecret)
        let type = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        let account = ACAccount(accountType: type)
        account?.credential = credential
        
        accountStore.saveAccount(account) { (succeed, error) in
            completion(succeed)
            if !succeed {
                NSLog("[TwitterAuth] ERROR saving new account to ACAccount:\n\(error?.localizedDescription)")
            }
        }
    }
    
    private func getTwitterAccounts(completion: @escaping (_ accounts: [ACAccount]?, _ error: TwitterAuthError?) -> ()) {
        let type = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: type, options: nil) { succeed, error in
            guard succeed else {
                return completion(nil, .noAccessToAccounts)
            }
            guard let accounts = self.accountStore.accounts(with: type) as? [ACAccount], !accounts.isEmpty else {
                    return completion(nil, .noAvailableAccounts)
            }
            completion(accounts, nil)
        }
    }
    
    private func showAccountsAlertView(onViewController vc: UIViewController,
        withAccounts accounts: [ACAccount],
        selectedAccountBlock: @escaping (_ selectedAccount: ACAccount) -> ()) {
            let alert = UIAlertController(title: "Available Accounts",
                message: "(Twitter)",
                preferredStyle: .actionSheet)
            accounts.forEach { account in
                let action = UIAlertAction(title: account.username,
                    style: .default) { (action) in
                        selectedAccountBlock(account)
                }
                alert.addAction(action)
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(cancel)
            
            Threading.executeOnMainThread {
                vc.present(alert, animated: true, completion: nil)
            }
    }
}

