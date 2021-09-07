import Foundation

struct JobTalk {
    /* This struct defines "caseless enums".  They are, I think, esseitnally
     string constants with the syntactic sugar of fancy hierarchical naming.
     It would be nice to use regular enum for the Commands, and I tried that,
     but enums are not JSON encodeable, so I would need to use either Swift
     Encode/Decode or NSCoding (NSKeyedArchiver) over the sockets instead of
     JSON.  I tried the Swift Encode/Decode and ended up going down into a
     rabbit hole of protocol / generic constraint / typealias error crap while
     trying to make things Hashable and Encodable.  Maybe this is not possible:
     https://forums.swift.org/t/serializing-a-dictionary-with-any-codable-values/16676/7
     Regarding the other alternative, I know that NSKeyedArchiver is a pain
     due to secure coding requirements.  Another idea is to maybe override
     JSONEncoder and JSONDecoder, defining an "extended JSON" protocol which
     would handle Swift enums.  But not today, not in this demo project. */
    
    enum Keys {
        static let command = "command"
        static let jobDataIn = "jobDataIn"
        static let jobDataOut = "jobDataOut"
    }

    enum Commands {
        static let whatTimeIsIt = "whatTimeIsIt"
        static let multiplyEachElementBy2 = "multiplyEachElementBy2"
        static let unknownCommand = "unknownCommand"
    }
}
