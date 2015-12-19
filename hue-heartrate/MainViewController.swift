//
//  ViewController.swift
//  hue-heartrate
//
//  Created by Kasra Rahjerdi on 12/18/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import UIKit
import HealthKit

class MainViewController: UIViewController {
    
    var hkStore: HKHealthStore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hkStore = HKHealthStore()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    private func initHealthStore(hkStore: HKHealthStore) {
        let sampleTypes = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        
        hkStore.requestAuthorizationToShareTypes([sampleTypes], readTypes: [sampleTypes]) {
            (success: Bool, error: NSError?) -> Void in
            if (!success || error != nil) {
                let alertController = UIAlertController(title: "Error initializing HealthKit", message: error == nil ? "Unknown error :(" : error!.localizedDescription, preferredStyle: .Alert)
                let action = UIAlertAction(title: "Try again?", style: .Default, handler: nil)
                alertController.addAction(action)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
}

