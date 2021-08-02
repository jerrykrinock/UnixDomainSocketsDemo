import Foundation

class CommSocket {
    var sockRefValid = false
    var sockConnected = false
    var sockRef: CFSocket?
    var sockUrl: URL?
    var sockAddress: Data?
    var sockLastError: Error?

    static func toHelperUrl() -> URL {
        var url = URL.init(fileURLWithPath:NSHomeDirectory())
        url = url.appendingPathComponent("UDSDToHelper.socket")
        return url
    }
    
    static func fromHelperUrl() -> URL {
        var url = URL.init(fileURLWithPath:NSHomeDirectory())
        url = url.appendingPathComponent("UDSDFromHelper.socket")
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
