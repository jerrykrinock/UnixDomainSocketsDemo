struct UDSDError: Error {
    enum Kind {
        case couldNotLaunchHelper
    }
    
    let kind: Kind
}

