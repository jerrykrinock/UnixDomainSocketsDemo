struct DemoError: Error {
    enum Kind {
        case couldNotLaunchHelper
    }
    
    let kind: Kind
}

