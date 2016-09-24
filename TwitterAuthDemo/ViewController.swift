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
        label.textAlignment = .center
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
        label.textAlignment = .center
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
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    
    var accounts: [ACAccount] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.frame = view.bounds
        tableView.frame.size = CGSize(width: view.bounds.width, height: view.bounds.height/2)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseID)
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
        twitterAuth.saveInACAccounts = true
        lookForAccounts()
    }
    
    func addNavBarButtons() {
        let alertButton = UIBarButtonItem(title: "Show Alert", style: .plain, target: self, action: #selector(ViewController.showReverseOAuthAlert))
        navigationItem.setRightBarButton(alertButton, animated: true)
        let webButton = UIBarButtonItem(title: "Web Login", style: .plain, target: self, action: #selector(ViewController.openWebLogin))
        navigationItem.setLeftBarButton(webButton, animated: true)
    }
    
    func lookForAccounts(_ completion: ((Bool) -> Void)? = nil) {
        let accountStore = ACAccountStore()
        let type = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: type, options: nil) { succeed, error in
            if succeed {
                guard let accounts = accountStore.accounts(with: type) as? [ACAccount] else { return }
                if accounts.isEmpty { print("No available accounts") }
                self.accounts = accounts
            }
            completion?(succeed)
        }
    }
    
    func showReverseOAuthAlert() {
        twitterAuth.executeReverseOAuthWithAvailableAccounts(onViewController: self, completion: displayResultOnScreen)
    }
    
    func openWebLogin() {
        twitterAuth.presentWebLogin(fromViewController: self)
    }
    
    func displayResultOnScreen(_ result: TwitterAuthResult?, error: TwitterAuthError?) {
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
    
    func showAlert(_ text: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Alert",
                message: text,
                preferredStyle: .alert)
            let cancel = UIAlertAction(title: "OK", style: .cancel) { _ in
                alert.dismiss(animated: true, completion: nil)
            }
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: TableView
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseID)
        cell.textLabel?.text = accounts[indexPath.row].username
        cell.detailTextLabel?.text = String(describing: accounts[indexPath.row].accountType)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        twitterAuth.executeReverseOAuth(forAccount: accounts[indexPath.row], completion: displayResultOnScreen)
    }
}

extension ViewController: TwitterAuthWebLoginDelegate {
    
    func didSuccedRetrivingToken(_ result: TwitterAuthResult) {
        displayResultOnScreen(result, error: nil)
        lookForAccounts { succeed in
            if succeed { self.tableView.reloadData() }
        }
    }
    
    func didFailRetrievingToken(_ error: TwitterAuthError) {
        displayResultOnScreen(nil, error: error)
    }
}
