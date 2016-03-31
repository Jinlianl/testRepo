//
//  ViewController.swift
//  Beacon_demo
//
//  Created by Terry Liao on 16/1/14.
//  Copyright © 2016年 Terry Liao. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController ,CLLocationManagerDelegate{
    
    struct beaconInfo {
        var Major:NSNumber
        var Minor:NSNumber
        var addrX:Double
        var addrY:Double
    }
    
    @IBOutlet weak var method_lable: UILabel!
    
    @IBOutlet weak var Position: UILabel!
    
    
    var beaconList:[beaconInfo] = []
    let locationManager = CLLocationManager()
    let region = CLBeaconRegion(proximityUUID:NSUUID(UUIDString: "F7826DA6-4FA2-4E98-8024-BC5B71E0893E")!, identifier: "Kontakt")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        if(CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse){
            locationManager.requestWhenInUseAuthorization()
        }
        make_list()
        locationManager.startRangingBeaconsInRegion(region)
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        let knownBeacons = beacons.filter{$0.proximity != CLProximity.Unknown}

        //Get position through tag reconition
        
        var info:[(ID:NSNumber, Proximity: Int, Accuracy: CLLocationAccuracy,  Mass:Double)] = []
        print(knownBeacons.count)
        print("\n")
        for aBeacon in knownBeacons{
            if Int(aBeacon.minor) != 3 {
                continue
            }
			method_lable.text = String(aBeacon.accuracy)
			Position.text = String(aBeacon.proximity.hashValue)
			let mass = calcMass(aBeacon)
              info.append((ID: aBeacon.minor, Proximity: aBeacon.proximity.hashValue, Accuracy: aBeacon.accuracy, Mass: mass))
            
        }
        
        for i in 0...info.count - 1{
             print(info[i])
        }
        print("\n\n")
       
        
        
        
        
//        //Get position through Triangulation
//        if(knownBeacons.count >= 3 && flag == 0){
//            method_lable.text = String("Tri Method")
//            (x,y) = calcPosition(knownBeacons)
//            x = NSString(format: "%.2f", x).doubleValue
//            y = NSString(format: "%.2f", y).doubleValue
//            print("[tri pos]the cordinate is \(x,y)")
//        
//        }
//        
//        Position.text = String("\(x),\(y)")
        
        
    }
    
    func make_list(){
        
        beaconList.append(beaconInfo(Major: 101, Minor: 1, addrX: 50, addrY: 3))
        beaconList.append(beaconInfo(Major: 101, Minor: 2, addrX: 5, addrY: 96))
        beaconList.append(beaconInfo(Major: 101, Minor: 3, addrX: 99, addrY: 98))
        beaconList.append(beaconInfo(Major: 101, Minor: 4, addrX: 0, addrY: 0))
        
    }
    
    func calcPosition(Beacons : [CLBeacon])->(pX:Double, pY: Double){ //return the positioning cordinate
        var useIndex :[Int] = []
        let useBeaconNum = 3
        var match:[(infoNum: Int, bcNum: Int)] = []

        
        for i in 0...(useBeaconNum - 1){
            for j in 0...beaconList.count-1 {
                if (Beacons[i].minor == beaconList[j].Minor){
                    useIndex.append(j)//the beacon index list use for positioning
                     match.append((j,i))
                }
            }
        }
        
        for i in 0...(useBeaconNum - 1){
            print("becNum:\(useIndex[i]) x: \(beaconList[useIndex[i]].addrX) y: \(beaconList[useIndex[i]].addrY)\n")
        }
        
        
        
        let xa = beaconList[useIndex[0]].addrX
        let xb = beaconList[useIndex[1]].addrX
        let xc = beaconList[useIndex[2]].addrX
        let ya = beaconList[useIndex[0]].addrY
        let yb = beaconList[useIndex[1]].addrY
        let yc = beaconList[useIndex[2]].addrY
        
        var aIndex:Int = 0
        var bIndex:Int = 0
        var cIndex:Int = 0
        for i in 0...match.count-1{
            if (useIndex[0] == match[i].infoNum){
                aIndex = match[i].bcNum
            }else if(useIndex[1] == match[i].infoNum){
                bIndex = match[i].bcNum
            }else{
                cIndex = match[i].bcNum
            }
        }
        
        
        
        let da = rssi2Dist(Beacons[aIndex])
        let db = rssi2Dist(Beacons[bIndex])
        let dc = rssi2Dist(Beacons[cIndex])
        
        let va = ((db*db-dc*dc) - (xb*xb-xc*xc) - (yb*yb-yc*yc)) / 2.0;
        let vb = ((db*db-da*da) - (xb*xb-xa*xa) - (yb*yb-ya*ya)) / 2.0;
        
        let temp1 = vb*(xc-xb) - va*(xa-xb);
        let temp2 = (ya-yb)*(xc-xb) - (yc-yb)*(xa-xb);
        
        let y = temp1 / temp2;
        let x = (va - y*(yc-yb)) / (xc-xb);
        
        
        return (x,y)
    }
    
    
    func rssi2Dist(Beacon:CLBeacon)->Double{
        let Accuracy = Beacon.accuracy
        let rssi = Beacon.rssi
        var dist = 0.0
        if(Beacon.proximity.hashValue == 2){
            dist += 20;
            dist += (Accuracy - 0.2)*10
        }else{
            dist += 60;
        }

        print("rssi: \(rssi) accuracy\(Accuracy)")
        print("distance\(dist)")
        
        
        return dist
    }
    
}

func calcMass(Beacon:CLBeacon)->Double{
    
    var Mass = 0.0
    
    switch(Beacon.proximity){
    case .Immediate:
        Mass = 1000 + (1/Beacon.accuracy)
        break
    case .Near:
        Mass = 100 + (10/Beacon.accuracy)
        break
    case .Far:
        Mass = 10 + (100/Beacon.accuracy)
        break
    default:
        Mass = 1;
    }
    
    //        print("Prox: \(Beacon.proximity.hashValue) rssi: \(rssi) accuracy\(Accuracy)")
    //        print("distance\(dist)")
    
    
    
    return Mass
}

