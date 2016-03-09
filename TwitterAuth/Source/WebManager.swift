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
    var callbackStringURL: String = ""
    
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
        return NSURL(string: "https://api.twitter.com/oauth/authenticate?oauth_token=\(token)")!
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
    func safariViewController(controller: SFSafariViewController, activityItemsForURL URL: NSURL, title: String?) -> [UIActivity] {
        return []
    }
    
    /*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the view controller is dismissed modally. */
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        
    }
    
    /*! @abstract Invoked when the initial URL load is complete.
    @param success YES if loading completed successfully, NO if loading failed.
    @discussion This method is invoked when SFSafariViewController completes the loading of the URL that you pass
    to its initializer. It is not invoked for any subsequent page loads in the same SFSafariViewController instance.
    */
    func safariViewController(controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if !didLoadSuccessfully {
            
        }
        print("DID LOAD SUCCESSFULLY: \(didLoadSuccessfully)")
    }
}
