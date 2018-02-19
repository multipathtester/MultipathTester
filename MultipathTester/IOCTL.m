//
//  IOCTL.m
//  QUICTester
//
//  Created by Quentin De Coninck on 1/19/18.
//  Copyright © 2018 Universite Catholique de Louvain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOCTL.h"

@implementation IOCTL

+(void)test
{
    // Open socket
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd <= 0) {
        NSLog(@"Cannot open socket");
        return;
    }
    NSLog(@"Coucou");
    
    // Use ioctl to gain information from the socket
    // - Set ifconf buffer before executing ioctl
    // - SIOCGIFCONF command retrieves ifnet list and put it into struct ifconf
    char buffer[4000];
    struct ifconf ifc;
    ifc.ifc_len = 4000;
    ifc.ifc_ifcu.ifcu_buf = buffer;
    if (ioctl(sockfd, SIOCGIFCONF, &ifc) < 0) {
        NSLog(@"ioctl execution failed");
        close(sockfd);
        return;
    }
    
    // Loop through ifc to access struct ifreq
    // - ifc.ifc_buf now contains multiple struct ifreq, but we don't have any clue of where are those pointers are
    // - We have to calculate the next pointer location in order to loop...
    struct ifreq *p_ifr;
    NSMutableDictionary *allInterfaces = [NSMutableDictionary dictionary];
    for (char *p_index=ifc.ifc_buf; p_index < ifc.ifc_buf+ifc.ifc_len; ) {
        p_ifr = (struct ifreq *)p_index;
        
        NSString *interfaceName = [NSString stringWithCString:p_ifr->ifr_name encoding:NSASCIIStringEncoding];
        NSNumber *family = [NSNumber numberWithInt:p_ifr->ifr_addr.sa_family];
        NSString *address = nil;
        NSMutableDictionary *interfaceDict = nil;
        NSMutableDictionary *interfaceTypeDetailDict = nil;
        char temp[80];
        
        // Switch by sa_family
        // - Do nothing if sa_family is not one of supported types (like MAC or IPv4)
        switch (p_ifr->ifr_addr.sa_family) {
            case AF_LINK:
                // MAC address
                
                interfaceDict = [allInterfaces objectForKey:interfaceName];
                if (!interfaceDict) {
                    interfaceDict = [NSMutableDictionary dictionary];
                    [allInterfaces setObject:interfaceDict forKey:interfaceName];
                }
                
                interfaceTypeDetailDict = [interfaceDict objectForKey:family];
                if (!interfaceTypeDetailDict) {
                    interfaceTypeDetailDict = [NSMutableDictionary dictionary];
                    [interfaceDict setObject:interfaceTypeDetailDict forKey:family];
                }
                
                struct sockaddr_dl *sdl = (struct sockaddr_dl *) &(p_ifr->ifr_addr);
                int a,b,c,d,e,f;
                
                strcpy(temp, ether_ntoa((const struct ether_addr *)LLADDR(sdl)));
                sscanf(temp, "%x:%x:%x:%x:%x:%x", &a, &b, &c, &d, &e, &f);
                sprintf(temp, "%02X:%02X:%02X:%02X:%02X:%02X",a,b,c,d,e,f);
                
                address = [NSString stringWithCString:temp encoding:NSASCIIStringEncoding];
                [interfaceTypeDetailDict setObject:address forKey:@"address"];
                
                break;
                
            case AF_INET:
                // IPv4 address
                
                interfaceDict = [allInterfaces objectForKey:interfaceName];
                if (!interfaceDict) {
                    interfaceDict = [NSMutableDictionary dictionary];
                    [allInterfaces setObject:interfaceDict forKey:interfaceName];
                }
                
                interfaceTypeDetailDict = [interfaceDict objectForKey:family];
                if (!interfaceTypeDetailDict) {
                    interfaceTypeDetailDict = [NSMutableDictionary dictionary];
                    [interfaceDict setObject:interfaceTypeDetailDict forKey:family];
                }
                
                struct sockaddr_in *sin = (struct sockaddr_in *) &p_ifr->ifr_addr;
                
                strcpy(temp, inet_ntoa(sin->sin_addr));
                
                address = [NSString stringWithCString:temp encoding:NSASCIIStringEncoding];
                [interfaceTypeDetailDict setObject:address forKey:@"address"];
                
                break;
                
            default:
                // Anything else
                break;
                
        }
        
        // Don't forget to calculate loop pointer!
        p_index += sizeof(p_ifr->ifr_name) + MAX(sizeof(p_ifr->ifr_addr), p_ifr->ifr_addr.sa_len);
    }
    
    NSLog(@"allInterfaces = %@", allInterfaces);
    
    close(sockfd);
}

+(void)test2
{
    // Open socket
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd <= 0) {
        NSLog(@"Cannot open socket");
        return;
    }
    NSLog(@"Coucou");
    
    // Use ioctl to gain information from the socket
    // - Set ifconf buffer before executing ioctl
    // - SIOCGIFCONF command retrieves ifnet list and put it into struct ifconf
    struct ifreqfull ifr;
    strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
    int i = ioctl(sockfd, SIOCGIFLINKQUALITYMETRIC, &ifr);
    if (i < 0) {
        NSLog(@"ioctl execution failed");
        perror("iotcl");
        NSLog(@"%d %d", errno, EINVAL);
        close(sockfd);
        return;
    }
    
    NSLog(@"Sth worked...");
    NSLog(@"%d", ifr.ifr_link_quality_metric);
    
    close(sockfd);
}

@end


//class IOCTL {
//    static func test() {
//        let sock = socket(PF_INET, 1, 0)
//
//        var ic = ifconf()
//        let LEN: Int32 = 32000
//        ic.ifc_len = LEN
//        ic.ifc_ifcu.ifcu_buf = UnsafeMutablePointer<CChar>.allocate(capacity: Int(LEN))
//
//        // SIOCGIFCONF = 36
//        let io = ioctl(sock, UInt(SIOCGIF), &ic)
//        guard io >= 0 else {
//            perror("Error:")
//            print(errno)
//            return
//            //fatalError("ioctl failed")
//        }
//
//        let ifs = UnsafePointer<ifreq>(ic.ifc_ifcu.ifcu_req)!
//        let ifnum = Int(ic.ifc_len) / MemoryLayout<ifreq>.size
//
//        for id in 0..<ifnum {
//            let i = ifs[id]
//            var name = i.ifr_name
//            let ifname = withUnsafePointer(to: &name) {
//                _ = $0.withMemoryRebound(to: CChar.self, capacity: 1, { ptr in
//                    String(cString: ptr)
//                })
//            }
//
//            print(ifname)
//            print(i.ifr_ifru.ifru_addr.sa_data)
//        }
//
//        let res = close(sock)
//    }
//}

