//
//  NmapXMLParser.swift
//  NetMap
//
//  Created by kyb on 24/12/15.
//  Copyright © 2015 Suborbital Softworks Ltd. All rights reserved.
//

import Foundation
import SWXMLHash

class NmapXMLParser {
    var nextNodeID: Int = 0
    
    enum ParserError : ErrorType {
        case FileOpenError(String)
        case InvalidXMLError(Int)
    }
    
    func parseXMLFile(file: String) throws -> Project {
        guard let xmldata = NSData(contentsOfFile: file) else {
            throw ParserError.FileOpenError(file)
        }
        
        let xml = SWXMLHash.parse(xmldata)
        
        self.nextNodeID = 0
        let rootNode = try self.makeTreeFromXML(xml)
        let p = Project(representedFile: file, rootNode: rootNode)
        return p
    }
}

extension NmapXMLParser {
    func makeTreeFromXML(xml: XMLIndexer) throws -> Node {
        var rootNode = Node(id: self.nextNodeID++, type: .Network)

        //let's just do this here
        let root = try xml.byKey("nmaprun")
        if let hname = root.element?.attributes["startstr"] {
            rootNode.hostname = hname
        } else {
            throw ParserError.InvalidXMLError(1)
        }

        if let addr = root.element?.attributes["args"] {
            rootNode.address = addr
        } else {
            throw ParserError.InvalidXMLError(2)
        }

        let hosts = root.children.filter({$0.element?.name == "host"})
        for h in hosts {
            if h.element != nil {
                let addresses = h.children.filter({$0.element?.name == "address"})
                let hostnames = h.children.filter({$0.element?.name == "hostnames"})
                let ports = h["ports"].children.filter({$0.element?.name == "port"})
                
                var hnode = Node(id: self.nextNodeID++, type: .Host)
                if let addr = addresses.first?.element?.attributes["addr"] {
                    hnode.address = addr
                }
                if let hname = hostnames.first?.element?.attributes["name"] {
                    hnode.hostname = hname
                }
                for p in ports {
                    if p.element != nil {
                        var port = Port()
                        if let port_num_str = p.element?.attributes["portid"] {
                            if let port_num = Int(port_num_str) {
                                port.port = port_num
                            }
                        }
                        if let proto = p.element?.attributes["protocol"] {
                            port.proto = Port.Proto(string: proto)
                        }
                        
                        if let state = p["state"].element?.attributes["state"] {
                            port.state = Port.State(string: state)
                        }
                        
                        hnode.ports.append(port)
                    }
                }
                
                rootNode.appendChild(hnode)
            }
        }
        return rootNode;
    }
    
    func makeTree() throws -> Node {
        
        var rootNode = Node(id: self.nextNodeID++, type: .Network)
        rootNode.address = "10.0.0.0/24"
        rootNode.hostname = "Localnet"
        
        var router = Node(id: self.nextNodeID++, type: .Host)
        router.address = "10.0.0.1"
        router.hostname = "nighthawk.local"
        rootNode.appendChild(router)
        
        
        var rpi = Node(id: self.nextNodeID++, type: .Host)
        rpi.address = "10.0.0.2"
        rpi.hostname = "raspberrypi.local"
        rootNode.appendChild(rpi)
        
        var hans = Node(id: self.nextNodeID++, type: .Host)
        hans.address = "10.0.0.4"
        hans.hostname = "hans.local"
        rootNode.appendChild(hans)
        
        var franz = Node(id: self.nextNodeID++, type: .Host)
        franz.address = "10.0.0.6"
        franz.hostname = "franz.local"
        rootNode.appendChild(franz)
        
        var macbook = Node(id: self.nextNodeID++, type: .Host)
        macbook.address = "10.0.0.11"
        macbook.hostname = "ducks-macbook.local"
        rootNode.appendChild(macbook)
        
        var weles = Node(id: self.nextNodeID++, type: .Host)
        weles.address = "10.0.0.23"
        weles.hostname = "weles.celestialmachines.com"
        rootNode.appendChild(weles)
        
        return rootNode
    }
}