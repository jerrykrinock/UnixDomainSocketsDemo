# Unix Domain Sockets Demo

This project contains two Swift classes, and their superclass, and protocols, which provide an implementation of Unix Domain Sockets in macOS.  Unix Domain Sockets are nice because they provide interapplication communication without all of the security roadblocks of XPC.  These classes are powered by the CFSocket functions, which are available in Swift and are not deprecated.

## Deployment

You will only need the files in the UnixDomainSockets group in your project.  Files in the other groups, which are only needed for the demo, require macOS 11 or later, mainly due to SwiftUI stuff.  The UnixDomainSockets files are deployable to earlier versions – I'm not sure how early – if you remove the `@Published` from `@Published var sockClients` in the UDSServer class.

## Two Apps: Main and Helper

This demo builds two apps, *Main App* – the "client" which needs a service, and a *Helper App* – the service provider, that is, "server".  Presumably you have two apps which will be analagous to these.

## Instantiations of Client and Server

Clicking the first button in the Main App will launch a Helper App instance.  Upon launch, the Helper will instantiate a UDSServer.  Clicking the second button in the Main App will instantiate and start a UDSClient object in the Main App.  During this initialization, the UDSClient will open a connection with the UDSServer in the Helper.  This will cause the Helper's server to instantiate its own UDSClient, which we call a *connected client*.  In other words, although it is acting as a *server*, the Helper app will contain not only a UDSServer but also one UDSClient for every client that is connected to it.

## Jobs

The Main App has buttons to test several jobs…

### Small Job

Asks the helper/server for the time of day.  The server's response will be printed to the Event Log.

### Big Job

Sends an array of 10,000 numbers to the server.  The server will send back an array with each number multiplied by 2, and a truncated version of this response will be displayed in the Event Log.  This Big Job will probably require the server to *chunk* data into chunks of the socket buffer size.  Typically, in macOS 12, the socket buffer size is 8K bytes, so this job's data will be chunked into a dozen or so chunks.

### Full Disk Access Job

Asks server to send the data in the Safari bookmarks file.  This will only work if the Helper has been granted Full Disk Access in System Preferences > Security & Privacy > Privacy > Full Disk Access.


## Logging for Debugging

The Logger class is instantiated as a singleton and logs messages to the window in both the Main or Helper apps.  For portability, Logger is not called in any of the three core UnixDomainSockets files.  But you can add logging statements for debugging to any file in the project.  Like this: `Logger.shared.log("foo is \(bar)")`.

## Acknowledgement

I started this project by rewriting in Swift some Objective-C code written in 2012 by Sidney San Martín (aka s4y, https://s4y.us), from their answer in this Q&A:
https://stackoverflow.com/questions/989346/unix-domain-sockets-and-cocoa
