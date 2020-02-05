//
//  Util.swift
//  VB
//
//  Created by AlienLi on 2017/12/16.
//  Copyright © 2017年 MarcoLi. All rights reserved.
//

import UIKit
import MBProgressHUD
import Foundation
import CryptoSwift

let window = UIApplication.shared.keyWindow
var AutoFillData: Bool {
    return UserDefaults.standard.value(forKey: "globalAPIEnvironment") as? String == APIEnvironment.debug.rawValue
}

enum VBFont {
    case xxs
    case xs
    case s
    case m
    case l
    case xl
    case xxl
}

extension UIFont {
    static func vb_font(_ font: VBFont) -> UIFont {
        switch font {
        case .xxs:
            return UIFont.systemFont(ofSize: 8)
        case .xs:
            return UIFont.systemFont(ofSize: 12)
        case .s:
            return UIFont.systemFont(ofSize: 14)
        case .m:
            return UIFont.systemFont(ofSize: 16)
        case .l:
            return UIFont.systemFont(ofSize: 20)
        case .xl:
            return UIFont.systemFont(ofSize: 25)
        case .xxl:
            return UIFont.systemFont(ofSize: 30)
        }
    }
}

extension UIColor {
    static let vb_blue = UIColor.ccw.hex(0x0088EF)
    static let vb_yellow = UIColor.ccw.hex(0xFE892D)//FE892D//ff9D17
    static let vb_green = UIColor.ccw.hex(0x5BCD8F)
    static let vb_red = UIColor.ccw.hex(0xEE2342)
    static let vb_f9 = UIColor.ccw.hex(0xf9f9f9)
    static let vb_bg = UIColor.ccw.hex(0xf2f2f2)
    static let vb_line = UIColor.ccw.hex(0x000000, alpha: 0.12)
    static let vb_sepatater = UIColor.ccw.hex(0xEDEDED)
    static func vb_black(alpha: CGFloat) -> UIColor {
        return UIColor.ccw.hex(0x000000, alpha: alpha)
    }
    static func vb_white(alpha: CGFloat) -> UIColor {
        return UIColor.ccw.hex(0xffffff, alpha: alpha)
    }
}

class Util {

    fileprivate static let kIdentifier = "kCMIdentifier"
    private static let shared = Util()

    // 缓存：为了加速
    fileprivate var cachedRawDeviceId: String?
    fileprivate var cachedDeviceId: String?

    private class var keychain: Keychain {
        return Keychain.init(service: Bundle.main.bundleIdentifier!)
    }

    ///  生成 deviceId
    ///
    /// - Returns:
    public class func buildDeviceId() -> String {
        #if IDFA
            if let uid = ASIdentifierManager.shared().advertisingIdentifier?.uuidString, uid != "00000000-0000-0000-0000-000000000000" {
                return uid
            }
            return (UIDevice.current.identifierForVendor ??  UUID.init()).uuidString
        #else
            return (UIDevice.current.identifierForVendor ??  UUID.init()).uuidString
        #endif
    }

    // 加密算法
    class var aseCipher: AES? {
        // 必须为16位长度
        return try? AES.init(key: "COVERencryptK001", iv: "COVERencryptIK01")
    }

    ///  获取当前 deviceId
    ///
    /// - Returns:
    class func fetchCurrentDeviceId() -> String? {
        var hexDeviceId: String?
        if let deviceIdInUserDefault = UserDefaults.standard.string(forKey: kIdentifier) {
            hexDeviceId = deviceIdInUserDefault
        } else if let result = ((try? keychain.getString(kIdentifier)) as String??), let deviceIdInKeychain = result, !deviceIdInKeychain.isEmpty {
            hexDeviceId = deviceIdInKeychain
        }

        guard let hex = hexDeviceId, !hex.isEmpty else {
            return nil
        }

        // 是否加密
        guard !isValid(deviceId: hex) else {
            return hex
        }
        // 尝试解密
        if let hex = hexDeviceId, let ase = aseCipher, let ddata = try? Data.init(bytes: Array<UInt8>.init(hex: hex), count: Array<UInt8>.init(hex: hex).count).decrypt(cipher: ase), let dstr = String.init(data: ddata, encoding: .utf8), isValid(deviceId: dstr) {
            return dstr
        }
        return nil
    }

    /// 是否是合法的 id
    @inline(__always) class fileprivate func isValid(deviceId: String) -> Bool {
        return deviceId.count == UUID.init().uuidString.count
    }

    /// 保存 device id
    ///
    /// - Parameter deviceId:  设备 id
    class func save(deviceId: String) {
        // 加密
        if let iddata = deviceId.data(using: .utf8), let ase = aseCipher, let endata = try? iddata.encrypt(cipher: ase) {
            let dstr = endata.toHexString()
            UserDefaults.standard.set(dstr, forKey: kIdentifier)
        } else {
            UserDefaults.standard.set(deviceId, forKey: kIdentifier)
        }
        // keyChain 存放原始的就不加密
        _ = try? keychain.set(deviceId, key: kIdentifier)
    }

    /// 获取设备 id
    ///
    /// - Returns: 设备 id
    class func fetchDeviceId() -> String {
        let deviceId: String = fetchCurrentDeviceId() ?? buildDeviceId()
        save(deviceId: deviceId)
        return deviceId
    }

    /// 加固设备 id
    ///
    /// - Parameter deviceId: 设备 id
    /// - Returns: 加固后的设备 id
    class func reinforceDeviceId(deviceId: String) -> String {
        let md5: String = deviceId.md5()
        let tail = String.init(md5.suffix(4)).uppercased()
        var sign = ""
        for (i, c) in tail.unicodeScalars.enumerated() {
            sign.append(Character.init(UnicodeScalar.init((c.value + UInt32(i)) % 26 + 65)!))
        }
        return "\(deviceId)-\(sign.uppercased())"
    }

    /// 获取设备 id：原始的未加固的
    ///
    /// - Returns:  设备 id
    public class func getRawDeviceId() -> String {
        if let cache = shared.cachedRawDeviceId {
            return cache
        }

        let deviceId = fetchDeviceId()
        // 缓存
        shared.cachedRawDeviceId = deviceId
        return deviceId
    }

    /// 获取设备 id（已经过加固的）
    ///
    /// - Returns: 设备 id
    public class func getDeviceId() -> String {
        if let cache = shared.cachedDeviceId {
            return cache
        }

        let reinforcedId = reinforceDeviceId(deviceId: getRawDeviceId())
        // 缓存
        shared.cachedDeviceId = reinforcedId
        return reinforcedId
    }

    class func vb_Formatter() -> DateFormatter {
        let dateFormatter = DateFormatter.share
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter
    }

    class func vb_now() -> String {
        return Util.vb_Formatter().string(from: Date())
    }

    class func vb_thisDay() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let year =  components.year!
        let month = components.month!
        let day = components.day!

        let timeStr = "\(year)-\(month)-\(day) 00:00:00"
        return timeStr
    }

    class func vb_thisMonth() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let year =  components.year!
        let month = components.month!

        if month < 10 {
            let timeStr = "\(year)-0\(month)-01 00:00:00"
            return timeStr
        } else {
            let timeStr = "\(year)-\(month)-01 00:00:00"
            return timeStr
        }
    }

    class func getLastDayOfThisMonth() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let year =  components.year!
        let month = components.month!

        let lastDay = self.getNumberOfDaysInMonth()
        if month < 10 {
            let timeStr = "\(year)-0\(month)-\(lastDay) 23:59:59"
            return timeStr
        } else {
            let timeStr = "\(year)-\(month)-\(lastDay) 23:59:59"
            return timeStr
        }
    }

    // 获取本月的天数
    class func getNumberOfDaysInMonth() -> Int {
        let calendar = NSCalendar.init(identifier: NSCalendar.Identifier.gregorian)
        let range = calendar?.range(of: NSCalendar.Unit.day, in: NSCalendar.Unit.month, for: Date())
        return range?.length ?? 30
    }

    //计算指定月天数 如果是当月 返回当月天数
    class func getDaysInMonth( year: Int, month: Int) -> Int {
        if isCurrentMonth(year: year, month: month) {
            return Calendar.current.component(Calendar.Component.day, from: Date())
        } else {
            let calendar = Calendar.current

            var startComps = DateComponents()
            startComps.day = 1
            startComps.month = month
            startComps.year = year

            var endComps = DateComponents()
            endComps.day = 1
            endComps.month = month == 12 ? 1 : month + 1
            endComps.year = month == 12 ? year + 1 : year

            let startDate = calendar.date(from: startComps)!
            let endDate = calendar.date(from: endComps)!

            let diff = calendar.dateComponents([.day], from: startDate, to: endDate)
            return diff.day!
        }
    }

    class func isCurrentMonth(year: Int, month: Int) -> Bool {
        let calendar = Calendar.current
        let this_month = calendar.component(Calendar.Component.month, from: Date())
        let this_year = calendar.component(Calendar.Component.year, from: Date())
        if month == this_month && year == this_year {
            return true
        }
        return false
    }

    class func batchConfigLabelFont(labelArray: [UILabel], font: UIFont
        ) {
        _ = labelArray.map {
            $0.font = font
        }
    }

    class func batchConfigLabelTextAlignment(labelArray: [UILabel], alignment: NSTextAlignment
        ) {
        _ = labelArray.map {
            $0.textAlignment = alignment
        }
    }

    class func batchConfigLabelColor(labelArray: [UILabel], color: UIColor
        ) {
        _ = labelArray.map {
            $0.textColor = color
        }
    }

    class func batchConfigUserInteractionEnabled(views: [UIView], isUserInteractionEnabled: Bool? = true) {
        _ = views.map {
            $0.isUserInteractionEnabled = isUserInteractionEnabled ?? true
        }
    }
}

extension DateFormatter {
    static let share = DateFormatter()
}

extension Int {
    var vb_dateStyle: String {
        let date = Date.init(timeIntervalSince1970: TimeInterval.init(self / 1000))
        let dateformat = DateFormatter.share
        dateformat.dateFormat = "yyyy-MM-dd"
        let str = dateformat.string(from: date)
        return str
    }

    var vb_date_detail_style: String {
        let date = Date.init(timeIntervalSince1970: TimeInterval.init(self / 1000))
        let dateformat = DateFormatter.share
        dateformat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let str = dateformat.string(from: date)
        return str
    }

}

extension UIFont {
    class func vb_number_font(size: CGFloat) -> UIFont {
        return UIFont.init(name: "SFUDINMitAlt", size: size)!
    }
    class func vb_normal_font(size: CGFloat) -> UIFont {
//        return UIFont.init(name: "Roboto-Light", size: size)!
        return UIFont.init(name: "PingFangSC-Regular", size: size)!
    }
    class func vb_medium_font(size: CGFloat) -> UIFont {
        return UIFont.init(name: "PingFangSC-Medium", size: size)!
    }
    class func vb_bold_font(size: CGFloat) -> UIFont {
        return UIFont.init(name: "PingFangSC-Semibold", size: size)!
    }
}

typealias TimerExecuteClosure = @convention(block)()->Void
extension Timer {
    class func vb_scheduledTimerWithTimeInterval(_ ti: TimeInterval, closure: @escaping TimerExecuteClosure) -> Timer {
        return self.scheduledTimer(timeInterval: ti,
                                   target: self,
                                   selector: #selector(Timer.executeTimerClosure(_:)),
                                   userInfo: unsafeBitCast(closure,
                                                                                                                                                to: AnyObject.self),
                                   repeats: true)
    }

    @objc class func executeTimerClosure(_ timer: Timer) {
        let closure = unsafeBitCast(timer.userInfo as AnyObject, to: TimerExecuteClosure.self)
        closure()
    }
}

extension MBProgressHUD {

    class func dismissHUD(view: UIView?) {
        guard let view = view else { return }
        MBProgressHUD.hide(for: view, animated: true)
    }

    class func showIndicator(text: String, onView: UIView?) {
        guard let onView = onView else {return }
        MBProgressHUD.hide(for: onView, animated: false)
        let hud = MBProgressHUD.showAdded(to: onView, animated: true)
        hud.mode = .indeterminate
        hud.label.text = text
    }
    class func show(text: String, onView: UIView?, delay: Float = 1.0, handler: (() -> Void)? = nil) {
        guard let onView = onView else {return }

        MBProgressHUD.hide(for: onView, animated: false)
        let hud = MBProgressHUD.showAdded(to: onView, animated: true)
        hud.mode = .text
        hud.label.text = text
        hud.hide(animated: true, afterDelay: TimeInterval.init(delay))
        if let h = handler {
            DispatchQueue.main
                .asyncAfter(deadline: DispatchTime.now() + TimeInterval.init(delay),
                            execute: h)
        }
    }

    class func show(VBError: Error, onView: UIView?) {
        guard let onView = onView else {return}

        guard let err = VBError as? VBError, err.errorMessage != "" else {
            return

        }
        self.show(text: err.errorMessage, onView: onView, delay: 1.0, handler: nil)
    }
}

extension String {
    func subString(start: Int, length: Int = -1) -> String {
        if self == "" {
            return ""
        }
        if self.count < (start + length) {
            return self
        }
        var len = length
        if len == -1 {
            len = self.count - start
        }
        let st = self.index(startIndex, offsetBy: start)
        let en = self.index(st, offsetBy: len)
        return String(self[st ..< en])
    }
}

//enum Validate {
//    case phoneNum(_: String)
//    var isRight: Bool {
//        var predicateStr: String!
//        var currObject: String!
//        switch self {
//        case let .phoneNum(str):
//            predicateStr = "^((13[0-9])|(15[^4,\\D]) |(17[0,0-9])|(18[0,0-9])|(15[0,0-9]))\\d{8}$"
//            currObject = str
//        }
//        let predicate =  NSPredicate(format: "SELF MATCHES %@", predicateStr)
//        return predicate.evaluate(with: currObject)
//    }
//}

extension String {
    /// 验证身份证号码
    func validateIDCardNumber() -> Bool {
        struct Static {
            fileprivate static let predicate: NSPredicate = {
                let regex = "(^\\d{15}$)|(^\\d{17}([0-9]|X)$)"
                let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regex])
                return predicate
            }()
            fileprivate static let provinceCodes = [
                "11", "12", "13", "14", "15",
                "21", "22", "23",
                "31", "32", "33", "34", "35", "36", "37",
                "41", "42", "43", "44", "45", "46",
                "50", "51", "52", "53", "54",
                "61", "62", "63", "64", "65",
                "71", "81", "82", "91"]
        }
        // 初步验证
        guard Static.predicate.evaluate(with: self) else {
            return false
        }
        // 验证省份代码。如果需要更精确的话，可以把前六位行政区划代码都列举出来比较。
        let provinceCode = String(self.prefix(2))
        guard Static.provinceCodes.contains(provinceCode) else {
            return false
        }
        if self.count == 15 {
            return self.validate15DigitsIDCardNumber()
        } else {
            return self.validate18DigitsIDCardNumber()
        }
    }

    /// 15位身份证号码验证。
    // 6位行政区划代码 + 6位出生日期码(yyMMdd) + 3位顺序码
    private func validate15DigitsIDCardNumber() -> Bool {
        let birthdate = "19\(self.substring(from: 6, to: 11)!)"
        return birthdate.validateBirthDate()
    }

    /// 18位身份证号码验证。
    // 6位行政区划代码 + 8位出生日期码(yyyyMMdd) + 3位顺序码 + 1位校验码
    private func validate18DigitsIDCardNumber() -> Bool {
        let birthdate = self.substring(from: 6, to: 13)!
        guard birthdate.validateBirthDate() else {
            return false
        }
        struct Static {
            static let weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
            static let validationCodes = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
        }
        // 验证校验位
        let digits = self.substring(from: 0, to: 16)!.map { Int("\($0)")! }
        var sum = 0
        for i in 0..<Static.weights.count {
            sum += Static.weights[i] * digits[i]
        }
        let mod11 = sum % 11
        let validationCode = Static.validationCodes[mod11]
        return hasSuffix(validationCode)
    }

    private func validateBirthDate() -> Bool {
        struct Static {
            static let dateFormatter: DateFormatter = {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                return dateFormatter
            }()
        }
        if Static.dateFormatter.date(from: self) != nil {
            return true
        } else {
            return false
        }
    }

    private func substring(from: Int, to: Int) -> String? {
        guard to >= from && from >= 0 && to < count else {
            return nil
        }
        let startIdx = self.index(startIndex, offsetBy: from)
        let endIdx = self.index(startIndex, offsetBy: to)
        return String(self[startIdx...endIdx])
    }
}

let AUTO_LAYOUT = Z_SCREEN_WIDTH / 375.0
//是否是iphoneX系列手机
var isIphoneX: Bool = {
    if #available(iOS 11.0, *), window?.safeAreaInsets.bottom > 0.0 {
        return true
    } else {
        // Fallback on earlier versions
        return false
    }
}()
var navHeight: Double = {
    if #available(iOS 11.0, *) {
        if window?.safeAreaInsets.bottom > 0.0 {
            return 88.0
        } else {
            return 64.0
        }
    } else {
        // Fallback on earlier versions
        return 64
    }
}()

var tabbarHeight: Double = {
    if #available(iOS 11.0, *) {
        if window?.safeAreaInsets.bottom > 0.0 {
            return 83.0
        } else {
            return 49.0
        }
    } else {
        // Fallback on earlier versions
        return 49.0
    }
}()

extension UIImage {
    class func createImage(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        // 开启位图上下文
        UIGraphicsBeginImageContext(rect.size)
        // 获取位图上下文
        let context = UIGraphicsGetCurrentContext()
        // 使用color演示填充上下文
        context?.setFillColor(color.cgColor)
        // 渲染上下文
        context?.fill(rect)
        // 从上下文中获取图片
        let theImage = UIGraphicsGetImageFromCurrentImageContext()
        // 结束上下文
        UIGraphicsEndImageContext()
        return theImage!
    }
}

func dateWithOffsetDay(date: Date, day: Int) -> String {
    let formmater = DateFormatter()
    formmater.dateFormat = "yyyy-MM-dd HH:mm:ss"
    var dateComponents = DateComponents()
    dateComponents.day = day
    let newDate = NSCalendar.current.date(byAdding: dateComponents, to: date)
    if newDate != nil {
        return formmater.string(from: newDate!)
    } else {
        return ""
    }
}

func dateWithOffsetMonth(date: Date, month: Int) -> String {
    let formmater = DateFormatter()
    formmater.dateFormat = "yyyy-MM-dd HH:mm:ss"
    if month == 0 {
        return formmater.string(from: date)
    }
    var dateComponents = DateComponents()
    dateComponents.month = month
    dateComponents.day = -1
    let newDate = NSCalendar.current.date(byAdding: dateComponents, to: date)
    if newDate != nil {
        return formmater.string(from: newDate!)
    } else {
        return ""
    }
}

func dateWithOffsetYear(date: Date, year: Int) -> String {
    let formmater = DateFormatter()
    formmater.dateFormat = "yyyy-MM-dd HH:mm:ss"
    var dateComponents = DateComponents()
    dateComponents.year = year
    let newDate = NSCalendar.current.date(byAdding: dateComponents, to: date)
    if newDate != nil {
        return formmater.string(from: newDate!)
    } else {
        return ""
    }
}

//生成二维码
func createQRForString(qrString: String?, avatar: UIImage?) -> UIImage? {
    if let sureQRString = qrString {
        let stringData = sureQRString.data(using: String.Encoding.utf8, allowLossyConversion: false)
        //创建一个二维码的滤镜
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")
        qrFilter?.setValue(stringData, forKey: "inputMessage")
        qrFilter?.setValue("H", forKey: "inputCorrectionLevel")
        let qrCIImage = qrFilter?.outputImage

        // 创建一个颜色滤镜,黑白色
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(qrCIImage, forKey: "inputImage")
        colorFilter.setValue(CIColor(red: 0, green: 0, blue: 0), forKey: "inputColor0")
        colorFilter.setValue(CIColor(red: 1, green: 1, blue: 1), forKey: "inputColor1")
        // 返回二维码image
        let codeImage = UIImage(ciImage: (colorFilter.outputImage!.transformed(by: CGAffineTransform(scaleX: 15, y: 15))))

        // 中间一般放logo
        if let iconImage = avatar {
            let rect = CGRect(x: 0, y: 0, width: codeImage.size.width, height: codeImage.size.height)

            UIGraphicsBeginImageContext(rect.size)
            codeImage.draw(in: rect)
            let avatarSize = CGSize(width: rect.size.width*0.25, height: rect.size.height*0.25)
//            let context = UIGraphicsGetCurrentContext()!
            //添加圆形裁剪区域
//            context.addEllipse(in: CGRect(x: (codeImage.size.width-avatarSize.width)/2.0, y: (codeImage.size.height-avatarSize.height)/2.0, width: avatarSize.width, height: avatarSize.height))
//            context.clip()
            let x = (rect.width - avatarSize.width) * 0.5
            let y = (rect.height - avatarSize.height) * 0.5
            iconImage.draw(in: CGRect(x: x, y: y, width: avatarSize.width, height: avatarSize.height))

            let resultImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()
            return resultImage
            //            return createHDQRImage(originalImage: (resultImage?.ciImage)!)
        }
        return codeImage
    }
    return nil
}
///生成高清图片
func createHDQRImage(originalImage: CIImage) -> UIImage {

    //创建Transform
    let scale = 200 / originalImage.extent.width

    //    let transform = CGAffineTransform(scaleX: scale, y: scale)
    let transform = CGAffineTransform(scaleX: scale, y: scale)

    //放大图片
    let hdImage = originalImage.transformed(by: transform)
    return UIImage(ciImage: hdImage)
    //    return UIImage(CIImage: hdImage)

}



func dPrint<T>(_ message: T, fileName: String = #file, methodName: String = #function, lineNumber: Int = #line) {
    #if DEBUG
//    print("\(fileName as NSString)\n方法:\(methodName)\n行号:\(lineNumber)\n打印信息\(message)")
    print(message)
    #endif
}

func resizeImage(originalImg:UIImage) -> UIImage{
    
    //prepare constants
    let width = originalImg.size.width
    let height = originalImg.size.height
    let scale = width/height
    
    var sizeChange = CGSize()
    
    if width <= 1280 && height <= 1280{ //a，图片宽或者高均小于或等于1280时图片尺寸保持不变，不改变图片大小
        return originalImg
    }else if width > 1280 || height > 1280 {//b,宽或者高大于1280，但是图片宽度高度比小于或等于2，则将图片宽或者高取大的等比压缩至1280
        
        if scale <= 2 && scale >= 1 {
            let changedWidth:CGFloat = 1280
            let changedheight:CGFloat = changedWidth / scale
            sizeChange = CGSize(width: changedWidth, height: changedheight)
            
        }else if scale >= 0.5 && scale <= 1 {
            
            let changedheight:CGFloat = 1280
            let changedWidth:CGFloat = changedheight * scale
            sizeChange = CGSize(width: changedWidth, height: changedheight)
            
        }else if width > 1280 && height > 1280 {//宽以及高均大于1280，但是图片宽高比大于2时，则宽或者高取小的等比压缩至1280
            
            if scale > 2 {//高的值比较小
                
                let changedheight:CGFloat = 1280
                let changedWidth:CGFloat = changedheight * scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
                
            }else if scale < 0.5{//宽的值比较小
                
                let changedWidth:CGFloat = 1280
                let changedheight:CGFloat = changedWidth / scale
                sizeChange = CGSize(width: changedWidth, height: changedheight)
                
            }
        }else {//d, 宽或者高，只有一个大于1280，并且宽高比超过2，不改变图片大小
            return originalImg
        }
    }
    
    UIGraphicsBeginImageContext(sizeChange)
    
    //draw resized image on Context
    originalImg.draw(in: CGRect(x: 0, y: 0, width: sizeChange.width, height: sizeChange.height))
    
    //create UIImage
    guard let resizedImg = UIGraphicsGetImageFromCurrentImageContext() else { return originalImg }
    
    UIGraphicsEndImageContext()
    
    return resizedImg
    
}
