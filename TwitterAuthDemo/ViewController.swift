//
//  ViewController.swift
//  TwitterAuthDemo
//
//  Created by Pol Quintana on 08/03/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import UIKit
import Accounts
import TwitterAuth

let reuseID = "AccountCell"
let labelHeight: CGFloat = 100

let consumerKey = "" //PLACE YOUR CONSUMER TOKEN HERE
let consumerSecret = "" //PLACE YOUR CONSUMER SECRET HERE
let callbackURL = "reverse://authentication" //PLACE YOUR CALLBACK URL HERE

class ViewController: UIViewController {
    
    var twitterAuth = TwitterAuth.sharedInstance
    
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    lazy var tokenLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 20,
            y: self.view.frame.height/2,
            width: self.view.frame.width - 40,
            height: labelHeight)
        label.text = "Token:"
        label.textAlignment = .Center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var tokenSecretLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 20,
            y: self.view.frame.height/2 + labelHeight,
            width: self.view.frame.width - 40,
            height: labelHeight)
        label.text = "Token Secret:"
        label.textAlignment = .Center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.frame = CGRect(x: 20,
            y: self.view.frame.height/2 + labelHeight*2,
            width: self.view.frame.width - 40,
            height: labelHeight)
        label.text = "UserName:"
        label.textAlignment = .Center
        label.numberOfLines = 0
        return label
    }()
    
    
    var accounts: [ACAccount] = [] {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = view.bounds
        tableView.frame.size = CGSize(width: view.bounds.width, height: view.bounds.height/2)
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: reuseID)
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        view.addSubview(tableView)
        view.addSubview(tokenLabel)
        view.addSubview(tokenSecretLabel)
        view.addSubview(userNameLabel)
        title = "Available Accounts"
        addNavBarButtons()
        guard !consumerKey.isEmpty || !consumerSecret.isEmpty else {
            showAlert("Consumer Key and Secret are empty!")
            return
        }
        twitterAuth.configure(withConsumerKey: consumerKey, consumerSecret: consumerSecret, callbackURL: callbackURL)
        twitterAuth.webLoginDelegate = self
        lookForAccounts()
    }
    
    func addNavBarButtons() {
        let alertButton = UIBarButtonItem(title: "Show Alert", style: .Plain, target: self, action: "showReverseOAuthAlert")
        navigationItem.setRightBarButtonItem(alertButton, animated: true)
        let webButton = UIBarButtonItem(title: "Web Login", style: .Plain, target: self, action: "openWebLogin")
        navigationItem.setLeftBarButtonItem(webButton, animated: true)
    }
    
    func lookForAccounts() {
        let accountStore = ACAccountStore()
        let type = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(type, options: nil) { succeed, error in
            if succeed {
                guard let accounts = accountStore.accountsWithAccountType(type) as? [ACAccount] else { return }
                if accounts.isEmpty { self.showAlert("No available accounts") }
                self.accounts = accounts
            }
        }
    }
    
    func showReverseOAuthAlert() {
        twitterAuth.executeReverseOAuthWithAvailableAccounts(onViewController: self, completion: displayResultOnScreen)
    }
    
    func openWebLogin() {
        twitterAuth.presentWebLogin(fromViewController: self)
    }
    
    func displayResultOnScreen(result: TwitterAuthResult?, error: TwitterAuthError?) {
        guard let reverseAuthResult = result else {
            self.tokenLabel.text = ""
            self.tokenSecretLabel.text = "Error"
            self.userNameLabel.text = ""
            return
        }
        self.tokenLabel.text = "Token: \n\(reverseAuthResult.oauthToken)"
        self.tokenSecretLabel.text = "Token Secret: \n\(reverseAuthResult.oauthTokenSecret)"
        self.userNameLabel.text = "UserName: \n\(reverseAuthResult.userName)"
    }
    
    func showAlert(text: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: "Alert",
                message: text,
                preferredStyle: .Alert)
            let cancel = UIAlertAction(title: "OK", style: .Cancel) { _ in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }
            alert.addAction(cancel)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: TableView
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: reuseID)
        cell.textLabel?.text = accounts[indexPath.row].username
        cell.detailTextLabel?.text = String(accounts[indexPath.row].accountType)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        twitterAuth.executeReverseOAuth(forAccount: accounts[indexPath.row], completion: displayResultOnScreen)
    }
}

extension ViewController: TwitterAuthWebLoginDelegate {
    
    func didSuccedRetrivingToken(result: TwitterAuthResult) {
        displayResultOnScreen(result, error: nil)
    }
    
    func didFailRetrievingToken(error: TwitterAuthError) {
        displayResultOnScreen(nil, error: error)
    }
}
