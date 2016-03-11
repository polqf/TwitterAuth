//
//  WebManager.swift
//  TwitterAuth
//
//  Created by Pol Quintana on 08/03/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import UIKit
import Accounts
import SafariServices

class TwicketWebManager: NSObject {
    
    private var safariViewController: SFSafariViewController?
    
    var consumerKey: String = ""
    var consumerSecret: String = ""
    
    func openLogin(onViewController viewController: UIViewController, token: String) {
        _checkNecessaryProperties()
        let safariVC = SFSafariViewController(URL: loginURL(withToken: token))
        safariVC.delegate = self
        safariVC.modalPresentationStyle = .FormSheet
        self.safariViewController = safariVC
        viewController.navigationController?.presentViewController(safariVC, animated: true, completion: nil)
    }
    
    func clearSafariViewController() {
        safariViewController?.dismissViewControllerAnimated(true) {
            self.safariViewController?.delegate = nil
            self.safariViewController = nil
        }
    }
    
    
    //MARK: Private
    
    private func loginURL(withToken token: String) -> NSURL {
        return NSURL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=\(token)&force_login=true")!
    }
    
    private func _checkNecessaryProperties() {
        if consumerKey.isEmpty || consumerSecret.isEmpty {
            fatalError("You must call configure(consumerKey:consumerSecret:callback:) on TwitterAuth.sharedInstance before calling any other methods")
        }
    }
}

extension TwicketWebManager: SFSafariViewControllerDelegate {
    
    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully { return }
        TwitterAuth.sharedInstance.webLoginDelegate?.didFailRetrievingToken(.UnableToLoadWeb)
    }
}
