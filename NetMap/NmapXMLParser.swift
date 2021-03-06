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
    
    enum ParserError : Error {
        case fileOpenError(String)
        case invalidXMLError(Int)
    }
    
    func parseXMLFile(_ file: String) throws -> Project {
        guard let xmldata = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            throw ParserError.fileOpenError(file)
        }
        
        let xml = SWXMLHash.parse(xmldata)
        
        self.nextNodeID = 0
        let rootNode = try self.makeTreeFromXML(xml)
        let p = Project(representedFile: file, rootNode: rootNode)
        return p
    }
}

extension NmapXMLParser {
    func makeTreeFromXML(_ xml: XMLIndexer) throws -> Node {
        self.nextNodeID += 1
        let nodeid = self.nextNodeID
        
        var rootNode = Node(id: nodeid, kind: .network)
        
        //let's just do this here
        let root = try xml.byKey("nmaprun")
        if let hname = root.element?.allAttributes["startstr"] {
            rootNode.hostname = hname.text
        } else {
            throw ParserError.invalidXMLError(1)
        }
        
        if let addr = root.element?.allAttributes["args"] {
            rootNode.address = addr.text
        } else {
            throw ParserError.invalidXMLError(2)
        }
        
        let hosts = root.children.filter({$0.element?.name == "host"})
        for h in hosts {
            let addresses = h.children.filter({$0.element?.name == "address"})
            let hostnames = h["hostnames"].children.filter({$0.element?.name == "hostname"})
            let ports = h["ports"].children.filter({$0.element?.name == "port"})
            
            self.nextNodeID += 1
            let nodeid = self.nextNodeID
            var hnode = Node(id: nodeid, kind: .host)
            hnode.address = addresses.first?.element?.allAttributes["addr"]?.text ?? "Unknown Address"
            hnode.hostname = hostnames.first?.element?.allAttributes["name"]?.text // ?? "Unknown Hostname"
            
            for p in ports {
                var port = Port()
                port.rawValue = Int(p.element?.allAttributes["portid"]?.text ?? "0") ?? 0
                port.proto = Port.Proto(string: p.element?.allAttributes["protocol"]?.text ?? "Unknown")
                port.state = Port.State(string: p["state"].element?.allAttributes["state"]?.text ?? "Unknown")
                
                hnode.ports.append(port)
            }
            
            rootNode.appendChild(hnode)
        }
        return rootNode;
    }
}
