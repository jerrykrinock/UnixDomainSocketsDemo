import Foundation

class CommSocket : ObservableObject {
    var sockRefValid = false
    var sockConnected = false
    var sockRef: CFSocket?
    var sockUrl: NSURL?
    var sockRLSourceRef: CFRunLoopSource?
    
    struct UDSErr: Error {
        enum Kind {
            // Both Client and Server
            case systemFailedToCreateSocket
            case cannotConnectToNilSocket
            case cannotConnectToNilAddress
            case nested(identifier: String, underlying: Error)
            
            // Client only
            case receivedNonDictionary(typeReceived: String)
            case sendDataTimeout
            case sendDataUnspecifiedError
            case sendDataKnownUnknownError
            case connectToAddressTimeout
            case connectToAddressUnspecifiedError
            case connectToAddressKnownUnknownError
            case socketNotConnected
            case cannotCreateSocketAlreadyExists
            
            // Server only
            case socketAlreadyCreated
            case setSockAddressTimedOut
            case setAddressTimeout
            case setAddressUnspecifiedError
            case setAddressKnownUnknownError
        }
        
        let kind: Kind
    }

    func isSockRefValid() -> Bool {
        if (self.sockRef == nil) {
            return false
        }
        return CFSocketIsValid(self.sockRef)
    }
    
    func sockAddress() -> Data? {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX) // AF = address family

        var path = [Int8](repeating: 0, count: Int(104))
        if let url = self.sockUrl {
            Logger.shared.log("Creating socket with \(url)")
            if (url.getFileSystemRepresentation(&path, maxLength: Int(104))) {
                /* Swift imports fixed-size C arrays as tuples !!
                 https://oleb.net/blog/2017/12/swift-imports-fixed-size-c-arrays-as-tuples/ */
                /* Use this formula in Numbers.app, starting in row 2, to generate the following code:
                CONCATENATE("address.sun_path.", CONCATENATE(ROW()−2, CONCATENATE(" = path[", CONCATENATE(ROW()−2, "]")))) */
                address.sun_path.0 = path[0]
                address.sun_path.1 = path[1]
                address.sun_path.2 = path[2]
                address.sun_path.3 = path[3]
                address.sun_path.4 = path[4]
                address.sun_path.5 = path[5]
                address.sun_path.6 = path[6]
                address.sun_path.7 = path[7]
                address.sun_path.8 = path[8]
                address.sun_path.9 = path[9]
                address.sun_path.10 = path[10]
                address.sun_path.11 = path[11]
                address.sun_path.12 = path[12]
                address.sun_path.13 = path[13]
                address.sun_path.14 = path[14]
                address.sun_path.15 = path[15]
                address.sun_path.16 = path[16]
                address.sun_path.17 = path[17]
                address.sun_path.18 = path[18]
                address.sun_path.19 = path[19]
                address.sun_path.20 = path[20]
                address.sun_path.21 = path[21]
                address.sun_path.22 = path[22]
                address.sun_path.23 = path[23]
                address.sun_path.24 = path[24]
                address.sun_path.25 = path[25]
                address.sun_path.26 = path[26]
                address.sun_path.27 = path[27]
                address.sun_path.28 = path[28]
                address.sun_path.29 = path[29]
                address.sun_path.30 = path[30]
                address.sun_path.31 = path[31]
                address.sun_path.32 = path[32]
                address.sun_path.33 = path[33]
                address.sun_path.34 = path[34]
                address.sun_path.35 = path[35]
                address.sun_path.36 = path[36]
                address.sun_path.37 = path[37]
                address.sun_path.38 = path[38]
                address.sun_path.39 = path[39]
                address.sun_path.40 = path[40]
                address.sun_path.41 = path[41]
                address.sun_path.42 = path[42]
                address.sun_path.43 = path[43]
                address.sun_path.44 = path[44]
                address.sun_path.45 = path[45]
                address.sun_path.46 = path[46]
                address.sun_path.47 = path[47]
                address.sun_path.48 = path[48]
                address.sun_path.49 = path[49]
                address.sun_path.50 = path[50]
                address.sun_path.51 = path[51]
                address.sun_path.52 = path[52]
                address.sun_path.53 = path[53]
                address.sun_path.54 = path[54]
                address.sun_path.55 = path[55]
                address.sun_path.56 = path[56]
                address.sun_path.57 = path[57]
                address.sun_path.58 = path[58]
                address.sun_path.59 = path[59]
                address.sun_path.60 = path[60]
                address.sun_path.61 = path[61]
                address.sun_path.62 = path[62]
                address.sun_path.63 = path[63]
                address.sun_path.64 = path[64]
                address.sun_path.65 = path[65]
                address.sun_path.66 = path[66]
                address.sun_path.67 = path[67]
                address.sun_path.68 = path[68]
                address.sun_path.69 = path[69]
                address.sun_path.70 = path[70]
                address.sun_path.71 = path[71]
                address.sun_path.72 = path[72]
                address.sun_path.73 = path[73]
                address.sun_path.74 = path[74]
                address.sun_path.75 = path[75]
                address.sun_path.76 = path[76]
                address.sun_path.77 = path[77]
                address.sun_path.78 = path[78]
                address.sun_path.79 = path[79]
                address.sun_path.80 = path[80]
                address.sun_path.81 = path[81]
                address.sun_path.82 = path[82]
                address.sun_path.83 = path[83]
                address.sun_path.84 = path[84]
                address.sun_path.85 = path[85]
                address.sun_path.86 = path[86]
                address.sun_path.87 = path[87]
                address.sun_path.88 = path[88]
                address.sun_path.89 = path[89]
                address.sun_path.90 = path[90]
                address.sun_path.91 = path[91]
                address.sun_path.92 = path[92]
                address.sun_path.93 = path[93]
                address.sun_path.94 = path[94]
                address.sun_path.95 = path[95]
                address.sun_path.96 = path[96]
                address.sun_path.97 = path[97]
                address.sun_path.98 = path[98]
                address.sun_path.99 = path[99]
                address.sun_path.100 = path[100]
                address.sun_path.101 = path[101]
                address.sun_path.102 = path[102]
                address.sun_path.103 = path[103]
            }
        }
        address.sun_len = 104

        return Data(
            bytes: &address,
            count: MemoryLayout.size(ofValue:address)
        )
    }
    
    func sockLastError() -> String {
        return String(
            format: "%s (%d)",
            strerror(errno),
            errno)
    }
    
    static func toHelperUrl() -> NSURL {
        var url = NSURL.init(fileURLWithPath:NSHomeDirectory())
        url = url.appendingPathComponent("UDSDToHelper.socket")! as NSURL
        return url
    }
    
    static func fromHelperUrl() -> NSURL {
        var url = NSURL.init(fileURLWithPath:NSHomeDirectory())
        url = url.appendingPathComponent("UDSDFromHelper.socket")! as NSURL
        return url
    }
}

protocol CommSocketServerDelegate: AnyObject {
    func handleSocketServerStopped(_ server: CommSocketServer?)
    func handleSocketServerMsgDict(_ aDict: [AnyHashable : Any]?, from client: CommSocketClient?, error: Error?)
}

protocol CommSocketClientDelegate: AnyObject {
    func handleSocketClientDisconnect(_ client: CommSocketClient?)
    func handleSocketClientMsgDict(_ aDict: [AnyHashable : Any]?, client: CommSocketClient?, error: Error?)
}
