//
//  Extension.swift
//  VB
//
//  Created by aiden on 2018/8/28.
//  Copyright © 2018年 MarcoLi. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

extension Int {
    var moneyStyle: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        let number = formatter.string(from: NSNumber.init(value: self)) ?? "0"
        return number
    }
}

extension Double {
    var moneyStyle: String {
        return String(format: "%.2f", self)
    }
}

extension String {

    var moneyStyle: String {
        let d = Double(self)
        guard let money = d else {return "0.00"}
        return String(format: "%.2f", money)
    }

    func tranferTime() -> String {
        var str = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var date = formatter.date(from: self)
        if date == nil {
            formatter.dateFormat = "yyyy-MM"
            date = formatter.date(from: self)
            if date == nil {
                return self
            }
            formatter.dateFormat = "yyyy年MM月"
            str = formatter.string(from: date!)
            return str
        }
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        str = formatter.string(from: date!)
        return str
    }
}

extension UITableViewCell {
    static var identifier: String {
        return String(describing: self.classForCoder())
    }
}

extension UICollectionViewCell {
    static var identifier: String {
        return String(describing: self.classForCoder())
    }
}

extension UILabel {
    class func label(textColor: UIColor, font: UIFont) -> UILabel {
        let label = UILabel()
        label.textColor = textColor
        label.font = font
        return label
    }
}

extension Date {
    func transformYYMMdd() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    func transformYYMMddhhmmss() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}

extension UIView {
    /// 部分圆角
    ///
    /// - Parameters:
    ///   - corners: 需要实现为圆角的角，可传入多个
    ///   - radii: 圆角半径
    func corner(byRoundingCorners corners: UIRectCorner, radii: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radii, height: radii))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }

    func layerMask(byRoundingCorners corners: UIRectCorner) {
        let maskPath = UIBezierPath.init(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: self.bounds.size)
        let maskLayer = CAShapeLayer.init()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
}

extension UIImage {

    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

// --- transform_earth_from_mars ---
// 参考来源：https://on4wp7.codeplex.com/SourceControl/changeset/view/21483#353936
// Krasovsky 1940
//
// a = 6378245.0, 1/f = 298.3
// b = a * (1 - f)
// ee = (a^2 - b^2) / a^2;
let a: Double = 6378245.0
let ee: Double = 0.00669342162296594323

// --- transform_earth_from_mars end ---
// --- transform_mars_vs_bear_paw ---
// 参考来源：http://blog.woodbunny.com/post-68.html
let x_pi: Double = Double.pi * 3000.0 / 180.0

public extension CLLocation {
    
    /// 从地图坐标转化到火星坐标
    ///
    /// - Returns: CLLocation
    func locationMarsFromEarth() -> CLLocation {
        
        let (n_lat,n_lng) = CLLocation.transform_earth_from_mars(lat: self.coordinate.latitude, lng: self.coordinate.longitude)
        let coord_2d = CLLocationCoordinate2D(latitude: n_lat + self.coordinate.latitude, longitude: n_lng + self.coordinate.longitude)
        
        return CLLocation(coordinate: coord_2d, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.horizontalAccuracy, course: self.course, speed: self.speed, timestamp: self.timestamp)
    }
    
    /// 从火星坐标到地图坐标
    ///
    /// - Returns: CLLocation
    func locationEarthFromMars() -> CLLocation {
        
        let (n_lat,n_lng) = CLLocation.transform_earth_from_mars(lat: self.coordinate.latitude, lng: self.coordinate.longitude)
        let coord_2d = CLLocationCoordinate2D(latitude: self.coordinate.latitude - n_lat, longitude: self.coordinate.longitude - n_lng)
        
        return CLLocation(coordinate: coord_2d, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.horizontalAccuracy, course: self.course, speed: self.speed, timestamp: self.timestamp)
    }
    
    /// 从火星坐标转化到百度坐标
    ///
    /// - Returns: CLLocation
    func locationBaiduFromMars() -> CLLocation {
        
        let (n_lat,n_lng) = CLLocation.transform_mars_from_baidu(lat: self.coordinate.latitude, lng: self.coordinate.longitude)
        let coord_2d = CLLocationCoordinate2D(latitude: n_lat, longitude: n_lng)
        
        return CLLocation(coordinate: coord_2d, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.horizontalAccuracy, course: self.course, speed: self.speed, timestamp: self.timestamp)
    }
    
    /// 从百度坐标到火星坐标
    ///
    /// - Returns: CLLocation
    func locationMarsFromBaidu() -> CLLocation {
        let (n_lat,n_lng) = CLLocation.transform_baidu_from_mars(lat: self.coordinate.latitude, lng: self.coordinate.longitude)
        let coord_2d = CLLocationCoordinate2D(latitude: n_lat, longitude: n_lng)
        
        return CLLocation(coordinate: coord_2d, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.horizontalAccuracy, course: self.course, speed: self.speed, timestamp: self.timestamp)
        
    }
    
    /// 从百度坐标到地图坐标
    ///
    /// - Returns: CLLocation
    func locationEarthFromBaidu() -> CLLocation {
        
        let mars = self.locationMarsFromBaidu()
        let (n_lat,n_lng) = CLLocation.transform_earth_from_mars(lat: mars.coordinate.latitude, lng: mars.coordinate.longitude)
        let coord_2d = CLLocationCoordinate2D(latitude: self.coordinate.latitude - n_lat, longitude: self.coordinate.longitude - n_lng)
        
        return CLLocation(coordinate: coord_2d, altitude: self.altitude, horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.horizontalAccuracy, course: self.course, speed: self.speed, timestamp: self.timestamp)
    }
    
    private class func transform_earth_from_mars(lat: Double, lng: Double) -> (Double, Double) {
        if CLLocation.transform_sino_out_china(lat: lat, lng: lng) {
            return (lat, lng)
        }
        var dLat = CLLocation.transform_earth_from_mars_lat(lng - 105.0, lat - 35.0)
        var dLng = CLLocation.transform_earth_from_mars_lng(lng - 105.0, lat - 35.0)
        let radLat = lat / 180.0 * Double.pi
        var magic = sin(radLat)
        magic = 1 - ee * magic * magic
        let sqrtMagic:Double = sqrt(magic)
        dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * Double.pi)
        dLng = (dLng * 180.0) / (a / sqrtMagic * cos(radLat) * Double.pi)
        return (dLat,dLng)
    }
    private class func transform_earth_from_mars_lat(_ x: Double,_ y: Double) -> Double {
        var ret: Double = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))
        ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * Double.pi) + 40.0 * sin(y / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * Double.pi) + 320 * sin(y * Double.pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    private class func transform_earth_from_mars_lng(_ x: Double,_ y: Double) -> Double {
        var ret: Double = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x))
        ret += (20.0 * sin(6.0 * x * Double.pi) + 20.0 * sin(2.0 * x * Double.pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * Double.pi) + 40.0 * sin(x / 3.0 * Double.pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * Double.pi) + 300.0 * sin(x / 30.0 * Double.pi)) * 2.0 / 3.0
        return ret
    }
    private class func transform_mars_from_baidu(lat: Double, lng: Double) -> (Double,Double) {
        let x = lng , y = lat
        let z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) + 0.000003 * cos(x * x_pi)
        return (z * sin(theta) + 0.006, z * cos(theta) + 0.0065)
    }
    private class func transform_baidu_from_mars(lat: Double, lng: Double) -> (Double,Double) {
        let x = lng - 0.0065 , y = lat - 0.006
        let z =  sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) - 0.000003 * cos(x * x_pi)
        return (z * sin(theta), z * cos(theta))
    }
    private class func transform_sino_out_china(lat: Double, lng: Double) -> Bool {
        if (lng < 72.004 || lng > 137.8347) {
            return true
        }
        if (lat < 0.8293 || lat > 55.8271) {
            return true
        }
        return false
    }
}
