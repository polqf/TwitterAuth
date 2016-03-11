//
//  ViewController.swift
//  TwicketLoaderDemo
//
//  Created by Pol Quintana on 11/03/16.
//  Copyright © 2016 Pol Quintana. All rights reserved.
//

import UIKit
import TwicketLoader

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let loader = TwicketLoader.createLoaderInView(view)
        loader.showLoader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

