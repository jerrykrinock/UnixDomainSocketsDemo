# Unix Domain Sockets Demo

This project contains two Swift classes, and their superclass, and protocols, which provide an implementation of Unix Domain Sockets in macOS.  Unix Domain Sockets are nice because they provide interapplication communication without all of the security roadblocks of XPC.  These classes are powered by the CFSocket functions, which are available in Swift and are not deprecated.

Currently this project uses a function that requires macOS 12 or later.  I plan to provide an alternative code path soon.

## Deployment

You will only need the files in the UnixDomainSockets group in your project.  Files in the other groups, which are only needed for the demo, require macOS 11 or later, mainly due to SwiftUI stuff.  The UnixDomainSockets files are deployable to earlier versions – I'm not sure how early, if you remove the `@Published` from `@Published var sockClients` in the UDSServer class.

## Two Apps: Main and Helper

This demo builds two apps, *Main App*, the "client" which needs a service, and a *Helper App* which provides the service – a "server".  Presumably you have two apps which will be analagous to these.

## Instantiations of Client and Server

Clicking the first button in the Main App will launch a Helper.  Upon launch, the Helper will instantiate a UDSServer.  Clicking the second button in the Main App will instantiate and start a UDSClient object. During this initialization, the UDSClient will open a connection with the UDSServer in the Helper.  This will cause the Helper's server to instantiate its own UDSClient, which we call a *connected client*.  In other words, although it is acting as a *server*, the Helper app will contain not only a UDSServer but also one UDSClient for every client that is connected to it.

## Debugging

The Logger class conveniently logs strings to the window of either the Main or Helper app.  For portability, Logger is not called in any of the three core UnixDomainSockets files.  But you can add temporary add such logging statements to any file.  Example: `Logger.shared.log("foo is \(bar)")`.

## Acknowledgement

I started this project by rewriting in Swift some Objective-C code written in 2012 by Sidney San Martín (aka s4y, https://s4y.us), from their answer in this Q&A:
https://stackoverflow.com/questions/989346/unix-domain-sockets-and-cocoa
