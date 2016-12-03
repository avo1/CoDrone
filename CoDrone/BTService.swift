//
//  BTService.swift
//  CoDrone
//
//  Refer to the tutorial from
//  https://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//
//  Created by Dave Vo on 12/3/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let DRONE_NAME = "PETRONE 7118"
let DRONE_SERVICE_UUID = CBUUID(string: "C320DF00-7891-11E5-8BCF-FEFF819CDC9F")
let DRONE_DATA_UUID =    CBUUID(string: "C320DF01-7891-11E5-8BCF-FEFF819CDC9F")  // Notify
let DRONE_CONF_UUID =    CBUUID(string: "C320DF02-7891-11E5-8BCF-FEFF819CDC9F")  // Write

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([DRONE_SERVICE_UUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services!.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services! {
            if service.uuid == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == PositionCharUUID {
                    self.positionCharacteristic = (characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    
                    // Send notification that Bluetooth is connected and all required characteristics are discovered
                    self.sendBTServiceNotificationWithIsBluetoothConnected(true)
                }
            }
        }
    }
    
    // Mark: - Private
    
    func writePosition(_ position: UInt8) {
        // See if characteristic has been discovered before writing to it
        if let positionCharacteristic = self.positionCharacteristic {
            let data = Data(bytes: [position])
            self.peripheral?.writeValue(data, for: positionCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(_ isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NotificationCenter.default.post(name: Notification.Name(rawValue: BLEServiceChangedStatusNotification), object: self, userInfo: connectionDetails)
    }
    
}