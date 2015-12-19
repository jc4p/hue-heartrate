//
//  InterfaceController.swift
//  HueHeartrateWatch Extension
//
//  Created by Kasra Rahjerdi on 12/18/15.
//  Copyright © 2015 Kasra Rahjerdi. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import Alamofire

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    var hkStore: HKHealthStore?
    var workoutSession: HKWorkoutSession?
    var startDate: NSDate?
    let heartRateUnit = HKUnit(fromString: "count/min")
    var isRunning = false
    var query: HKAnchoredObjectQuery?
    
    @IBOutlet var watchLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!
    
    let RED_ALERT_BASE = "http://192.168.1.187:5000"

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        hkStore = HKHealthStore()
        initHealthStore(hkStore!)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func startPressed() {
        if (isRunning) {
            self.hkStore?.endWorkoutSession(self.workoutSession!)
            self.hkStore?.stopQuery(query!)
            self.startButton.setTitle("Start")
            self.isRunning = false
            self.startDate = nil
            return
        }
        
        self.workoutSession = HKWorkoutSession(activityType: .Other, locationType: .Indoor)
        self.workoutSession!.delegate = self;
        
        self.hkStore?.startWorkoutSession(workoutSession!)
        
        let heartrateType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: nil, options: .None)
        
        query = HKAnchoredObjectQuery(type: heartrateType!,
            predicate: predicate,
            anchor: nil,
            limit: Int(HKObjectQueryNoLimit)) { (query, newSamples, deletedSamples, newAnchor, error) -> Void in
                if(error != nil) {
                    print(error!.localizedDescription)
                    return
                }
                if (newSamples == nil) {
                    return
                }
                let lastSample = newSamples!.last as? HKQuantitySample
                let bpm = Int(lastSample!.quantity.doubleValueForUnit(self.heartRateUnit))
                
                self.setRate(bpm)
        }
        
        query!.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
            if(error != nil) {
                print(error!.localizedDescription)
                return
            }
            if (samples == nil) {
                return
            }
            let lastSample = samples!.last as? HKQuantitySample
            let bpm = Int(lastSample!.quantity.doubleValueForUnit(self.heartRateUnit))
            
            self.watchLabel.setText(String(bpm))
            Alamofire.request(.POST, self.RED_ALERT_BASE + "/beat", parameters: ["rate": bpm])
        }
        
        self.hkStore?.executeQuery(query!)
    }
    
    func setRate(bpm: Int) {
        self.watchLabel.setText(String(bpm))
        Alamofire.request(.POST, self.RED_ALERT_BASE + "/beat", parameters: ["rate": bpm])
            .response { request, response, data, error in
                if (error != nil) {
                    print(error!.localizedDescription)
                }
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didChangeToState toState: HKWorkoutSessionState, fromState: HKWorkoutSessionState, date: NSDate) {
        // stage changed toState at date
        if (toState == .Running) {
            startDate = date
            isRunning = true
            self.startButton.setTitle("Stop")
        }
    }
    
    func workoutSession(workoutSession: HKWorkoutSession, didFailWithError error: NSError) {
        // error!
    }
    
    private func initHealthStore(hkStore: HKHealthStore) {
        let sampleTypes = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
        
        hkStore.requestAuthorizationToShareTypes([sampleTypes], readTypes: [sampleTypes]) {
            (success: Bool, error: NSError?) -> Void in
            if (error != nil) {
                print(error!.localizedDescription)
            }
        }
    }

}
